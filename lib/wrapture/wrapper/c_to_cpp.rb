# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025 Joel E. Anderson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module Wrapture
  module Wrapper
    # A collection of wrappers for generating C++ wrappers for C code.
    module CToCpp
      extend Wrapper

      # Gives a list of ancestor classes of class spec, including a colon
      # prefix, if the class has ancestors. If not, an empty string is
      # returned instead.
      def self.ancestor_suffix(class_spec)
        if class_spec.child?
          ": public #{class_spec.parent_name}"
        elsif class_spec.exception?
          ': public std::exception'
        else
          ''
        end
      end

      # Returns a cast of the equivalent member of an instance of the given
      # class with the given name from one type to another.
      def self.cast_equivalent(class_spec, var_name, from, to)
        member_access = from.pointer? ? '->' : '.'
        struct = "struct #{class_spec.struct.name}"
        if [EQUIVALENT_STRUCT_KEYWORD, struct].include?(to)
          "#{if class_spec.pointer_wrapper?
               '*'
             end}#{var_name}#{member_access}equivalent"
        elsif [EQUIVALENT_POINTER_KEYWORD, "#{struct} *"].include?(to)
          "#{unless class_spec.pointer_wrapper?
               '&'
             end}#{var_name}#{member_access}equivalent"
        else
          raise "uncaught cast case: struct: '#{struct}', to '#{to}'"
        end
      end

      # Gives a code snippet that accesses the equivalent struct from
      # within the class using the given variable name.
      def self.class_struct(class_spec, var_name: 'this')
        name = "#{var_name}->equivalent"
        if class_spec.pointer_wrapper?
          "*(#{name})"
        else
          name
        end
      end

      # Gives a code snippet that accesses the equivalent struct pointer from
      # within the class using the given variable name.
      def self.class_struct_pointer(class_spec, var_name: 'this')
        name = "#{var_name}->equivalent"
        if class_spec.pointer_wrapper?
          name
        else
          "&(#{name})"
        end
      end

      # Retrieves a conversion proc which converts one source component to
      # another.
      #
      # TODO: for this to be a usable interface point, the semantics around
      # each of the parameters as well as what a converter must do needs to be
      # well-defined, documented, and tested thoroughly.
      def self.converter(from, to, context)
        context_class = context.owner # assume a FunctionSpec

        if from == :this
          from = CSource::CPointer.new(type_class_from_spec(context_class))
        end

        if from.is_a?(TypeSpec)
          from_class = context_class.type(from)
          from = type_class_from_spec(from_class) unless from_class.nil?
        end

        if to == :equivalent_struct
          to = C.equivalent_struct(context_class)
          raise MissingWrapped, context_class if to.nil?
        end

        if to == :equivalent_pointer
          to = C.equivalent_pointer(context_class)
          raise MissingWrapped, context_class if to.nil?
        end

        if from.is_a?(CppSource::CppClass) && !from.equivalent_member.nil?
          equivalent_c_type = from.equivalent_member.c_type
          if to == equivalent_c_type
            return proc { |val| "#{val}.equivalent" }
          elsif to == CSource::CPointer.new(equivalent_c_type)
            return proc { |val| "&#{val}.equivalent" }
          end
        end

        if from.is_a?(CSource::CPointer) &&
           from.c_type.is_a?(CppSource::CppClass) &&
           !from.c_type.equivalent_member.nil?
          equivalent_c_type = from.c_type.equivalent_member.c_type
          if to == equivalent_c_type
            return proc { |val| "#{val}->equivalent" }
          elsif to == CSource::CPointer.new(equivalent_c_type)
            return proc { |val| "&#{val}->equivalent" }
          end
        end

        proc {
          "TODO: conversion from #{from} to #{to} within context #{context}"
        }
      end

      # Gives the filename used for the declaration of a given spec.
      def self.declaration_filename(spec)
        "#{spec.upper_camel_case_name}.hpp"
      end

      # The headers needed to declare the given class. This does not necessarily
      # match the C includes for a spec. The includes for things like calling
      # wrapped functions and invoking error handling are not needed for the
      # declaration. Additional C++ includes may also be present to bring in
      # type declarations for parameters declared by Wrapture.
      def self.declaration_includes(class_spec)
        includes = []

        includes.concat(class_spec[:c].includes) if class_spec.wrapped.key?(:c)

        class_spec.functions.each do |func|
          func.params.each do |param|
            includes.concat(Wrapper::C.includes(param))

            param_type = class_spec.type(param.type)
            includes << declaration_filename(param_type) unless param_type.nil?
          end
        end

        class_spec.constants.each do |const|
          includes.concat(Wrapper::C.includes(const))
        end

        if class_spec.child?
          includes.concat(Wrapper::C.includes(class_spec.parent_spec))

          parent_spec = class_spec.type(class_spec.parent_name)
          includes << declaration_filename(parent_spec) unless parent_spec.nil?
        elsif class_spec.exception?
          includes << 'exception'
        end

        includes.uniq
      end

      # Generate a source file with the declaration of a class.
      def self.declare_class(class_spec, scope)
        class_name = class_spec.upper_camel_case_name
        namespace_words = if scope.decorate_wrapped_name?
                            Cpp.decorate_name_words(scope.name_words)
                          else
                            scope.name_words
                          end
        namespace = Named.snake_case_name(namespace_words)

        src = CppSource::CppSourceFile.new("#{class_name}.hpp")

        guard = header_guard(class_spec)
        src.puts("#ifndef #{guard}")
        src.puts("#define #{guard}")
        src.puts

        declaration_includes(class_spec).sort.each do |inc|
          src << CSource::CInclude.new(inc)
        end

        src.puts("namespace #{namespace} {")
        src.puts

        src.declare(defined_class_from_spec(class_spec))

        src.puts
        src.puts("} /* namespace #{namespace} */")
        src.puts
        src.puts("#endif /* #{guard} */")

        src
      end

      # Adds declarations to a block for the local parameters needed in a
      # member function wrapper.
      def self.declare_member_function_locals(blk, func_spec)
        blk << 'va_list variadic_args;' if func_spec.variadic?

        if wrapper_captures_return?(func_spec)
          return_type = func_spec.wrapped[:c].return_type
          if return_type.to_s == EQUIVALENT_STRUCT_KEYWORD
            return_type = C.equivalent_struct(func_spec.owner)
          end
          if return_type.to_s == EQUIVALENT_POINTER_KEYWORD
            return_type = C.equivalent_pointer(func_spec.owner)
          end
          blk << CSource::CDeclaration.new(return_type, 'return_val')
          blk.puts(';')
        end
      end

      # Generate the definition for a constructor function.
      def self.define_constructor(class_spec, func_spec)
        class_name = type_class_from_spec(class_spec)

        # TODO: pick up here, add check for return type equality to wrapped type
        # raise InvalidConstructor if this happens
        # need to add a unit test for this condition as well
        return_type = func_spec[:c].return_type
        if return_type.to_s == EQUIVALENT_STRUCT_KEYWORD
          return_type = C.equivalent_struct(class_spec)
        end
        if return_type.to_s == EQUIVALENT_POINTER_KEYWORD
          return_type = C.equivalent_pointer(class_spec)
        end
        if C.equivalent_type(class_spec) != return_type
          msg = "a constructor for #{class_name} returns #{return_type} " \
                'instead of the class equivalent ' \
                "#{C.equivalent_type(class_spec)}"
          raise InvalidConstructor, msg
        end

        func = Wrapture::CppSource::CppFunction.new(class_name)
        func_spec.params.each do |param_spec|
          param_type = param_spec.type
          param_name = param_spec.name
          decl = CppSource::CppDeclaration.new(param_type,
                                               name: param_name)

          decl.value = param_spec.default_value if param_spec.default_value?

          func.params << decl
        end

        func.puts("#{wrapped_function_call(func_spec)};")

        func
      end

      # Generate a source file with the definition of a class.
      def self.define_class(class_spec, scope)
        unless class_spec.definable?
          raise UndefinableSpec, "#{class_spec.name} is not definable"
        end

        namespace_words = if scope.decorate_wrapped_name?
                            Cpp.decorate_name_words(scope.name_words)
                          else
                            scope.name_words
                          end
        namespace = Named.snake_case_name(namespace_words)

        src = CppSource::CppSourceFile.new("#{class_spec.name}.cpp")

        definition_includes(class_spec).sort.each do |inc|
          src << CSource::CInclude.new(inc)
        end

        src.puts("namespace #{namespace} {")
        src.puts

        src << defined_class_from_spec(class_spec)

        wrapper = CToCppWrapper.new(class_spec)
        wrapper.define do |line|
          # src.puts(line)
          src.puts("// #{line}")
        end

        src.puts
        src.puts("} /* namespace #{namespace} */")

        src
      end

      # Generate a source file with the definition of an enumeration.
      def self.define_enum(enum_spec)
        src = SourceFile.new("#{enum_spec.name}.hpp")

        wrapper = CToCppWrapper.new(enum_spec)
        wrapper.define do |line|
          src.puts(line) unless line.nil?
        end

        src
      end

      # Creates a CppClass instance from a ClassSpec, with all members and
      # functions fully defined.
      def self.defined_class_from_spec(spec)
        # start with the type class, then build out the definitions
        cls = type_class_from_spec(spec)
        cls.doc = spec.doc

        if spec.child?
          cls.parent_name = spec.parent_name
        elsif spec.exception?
          cls.parent_name = 'std::exception'
        end

        spec.constants.each do |it|
          decl = CppSource::CppDeclaration.new(it.type, name: it.name,
                                                        value: it.value)
          decl.attributes << 'static'
          decl.attributes << 'const'

          cls.constants << decl
        end

        spec.constructors.each do |it|
          cls.constructors << define_constructor(spec, it)
        end

        cls.constructors << member_constructor(spec) if C.wrapped_members?(spec)

        if generate_pointer_constructor?(spec)
          cls.constructors << pointer_constructor(spec)
        end

        unless spec.destructor.nil?
          func = CppSource::CppFunction.new("~#{cls.name}")
          func << wrapped_function_call(spec.destructor)
          func << ';'
          cls.destructor = func
        end

        spec.method_specs.each do |meth_spec|
          cls.member_functions << member_function_from_spec(meth_spec)
        end

        if C.factory?(spec, spec.scope)
          cls.member_functions << factory_member_function(spec)
        end

        cls
      end

      # The name of the file that the definition of this spec will be written
      # to. This may be the same as the declaration filename for specs that are
      # not forward declared.
      def self.definition_filename(spec)
        if forward_declared?(spec)
          "#{spec.upper_camel_case_name}.cpp"
        else
          "#{spec.upper_camel_case_name}.hpp"
        end
      end

      # The includes needed in the definition file for the given class spec.
      def self.definition_includes(class_spec)
        inc = [declaration_filename(class_spec)]
        inc.concat(declaration_includes(class_spec))
        inc.concat(C.includes(class_spec))

        if C.factory?(class_spec, class_spec.scope)
          class_spec.scope.classes.each do |it|
            inc << declaration_filename(it) if C.overload?(class_spec, it)
          end
        end

        inc.uniq
      end

      # A static function that generates an instance of an overloaded struct's
      # class according to the rules that the struct fulfills.
      def self.factory_member_function(class_spec)
        factory_name = class_spec.upper_camel_case_name
        func_name = "New#{factory_name}"
        func = CppSource::CppFunction.new(func_name)
        func.static = true
        func.return_type = CppSource::CppType.new("#{factory_name} *")

        equivalent_type = C.equivalent_type(class_spec)
        func.params << CSource::CDeclaration.new(equivalent_type, 'equivalent')

        overload_classes = class_spec.scope.select do |it|
          C.overload?(class_spec, it)
        end

        blocks = overload_classes.map do |overload|
          variable_access = if equivalent_type.is_a?(CSource::CPointer)
                              'equivalent->'
                            else
                              'equivalent.'
                            end

          checks = C.equivalent_struct(overload).rules.map do |it|
            new_vals = it.vals.dup
            new_vals[0] = "#{variable_access}#{it.vals[0]}"

            CSource::CExpression.new(new_vals, it.operator)
          end

          check_expression = CSource::CExpression.new(checks, :and)

          CSource::CIf.new(check_expression) do |blk|
            class_name = overload.upper_camel_case_name
            blk.puts("return new #{class_name}( equivalent );")
          end
        end

        # make the else-if chain
        blocks.each_cons(2) do |pair|
          pair[0].else_block = pair[1]
        end

        # add the fallback default case
        blocks.last.else do |blk|
          blk.puts("return new #{factory_name}( equivalent );")
        end

        # add the chain of rule checks
        func << blocks[0]

        func
      end

      # True if this instance's spec has separate definition and declaration
      # files.
      def self.forward_declared?(spec)
        !spec.is_a?(EnumSpec)
      end

      # True if a pointer constructor should be generated for the given class.
      #
      # A pointer constructor is generated for a class where the wrapped struct
      # is already a pointer. The pointer constructor sets the wrapped struct
      # to the parameter, instead of calling any of the constructor functions.
      def self.generate_pointer_constructor?(class_spec)
        class_spec.wrapped.key?(:c) && class_spec[:c].is_a?(CSource::CPointer)
      end

      # The symbol to use for header guard checks.
      def self.header_guard(class_spec)
        "#{class_spec.screaming_snake_case_name}_HPP"
      end

      # The member constructor for a class spec.
      def self.member_constructor(class_spec)
        class_name = class_spec.upper_camel_case_name
        func = Wrapture::CppSource::CppFunction.new(class_name)

        func.params.concat(class_spec[:c].members)

        # TODO: why is this a map instead of each?
        class_spec[:c].members.map do |member|
          func.puts("this->equivalent.#{member.name} = #{member.name};")
        end

        func
      end

      # Define a member function based on a function spec.
      def self.member_function_from_spec(spec)
        func_name = spec.upper_camel_case_name
        func = Wrapture::CppSource::CppFunction.new(func_name)
        return_spec = spec.return_type
        func.return_type = Wrapture::CppSource::CppType.from_spec(return_spec)
        func.static = spec.static?
        func.virtual = spec.virtual?

        spec.params.each do |param_spec|
          param_type = param_spec.type
          param_name = param_spec.name
          decl = Wrapture::CppSource::CppDeclaration.new(param_type,
                                                         name: param_name)
          func.params << decl
        end

        declare_member_function_locals(func, spec)

        if spec.variadic?
          func.puts("va_start( variadic_args, #{spec.params[-2].name} );")
        end

        func.puts("#{wrapped_function_call(spec)};")

        func.puts('va_end( variadic_args );') if spec.variadic?

        if spec.return_overloaded?
          overload = "New#{spec.return_type.name.chomp('*').strip}"
          func.puts("return #{overload}( return_val );")
        end

        func
      end

      # True if the provided wrapped param spec can be cast to when used in this
      # function.
      def self.param_uses_equivalent?(func_spec, wrapped_param)
        param = func_spec.params.find { |p| p.name == wrapped_param.value }

        !param.nil? &&
          !wrapped_param.c_type.nil? &&
          func_spec.owner.type?(param.type)
      end

      # Gives an expression for using a given parameter.
      # Equivalent structs and pointers are resolved, as well as casts between
      # types if they are known within the scope of this function.
      def self.resolve_wrapped_param(func_spec, param)
        val = param.value
        conversion = if val == EQUIVALENT_STRUCT_KEYWORD
                       val = 'this'
                       converter(:this, :equivalent_struct, func_spec)
                     elsif val == EQUIVALENT_POINTER_KEYWORD
                       val = 'this'
                       converter(:this, :equivalent_pointer, func_spec)
                     elsif val == '...'
                       converter(:variadic_args, :variadic_args, func_spec)
                     # TODO: remove this predicate, and rely on the converter
                     # to make this determination itself
                     elsif param_uses_equivalent?(func_spec, param)
                       used_param = func_spec.params.find do |p|
                         p.name == param.value
                       end
                       converter(used_param.type, param.c_type, func_spec)
                     else
                       # use the plain param value and hope for the best
                       proc { |val| val }
                     end

        conversion.call(val)
      end

      # The pointer constructor for a class spec.
      def self.pointer_constructor(class_spec)
        class_name = class_spec.upper_camel_case_name
        func = Wrapture::CppSource::CppFunction.new(class_name)
        func.params << CSource::CDeclaration.new(class_spec[:c], 'equivalent')
        func << 'this->equivalent = equivalent;'
      end

      # Creates a CppClass instance from a ClassSpec, with enough information
      # available to use the class for type conversions.
      def self.type_class_from_spec(spec)
        class_name = spec.upper_camel_case_name
        cls = Wrapture::CppSource::CppClass.new(class_name)

        if C.equivalent_member?(spec)
          eqv = Wrapture::CSource::CDeclaration.new(spec[:c], 'equivalent')
          cls.data_members << eqv
          cls.equivalent_member = eqv
        elsif C.equivalent_ancestor?(spec)
          eqv = Wrapture::CSource::CDeclaration.new(spec[:c], 'equivalent')
          cls.equivalent_member = eqv
        end

        cls
      end

      # Generates a build for a C++ library wrapping a class.
      def self.wrap_class(class_spec, scope: Scope.new)
        set = CppSource::CppSourceSet.new(class_spec.name)

        set.add_lib_header(declare_class(class_spec, scope))
        set.add_lib_source(define_class(class_spec, scope))

        class_spec.libraries.each do |lib|
          set.add_lib_link(lib)
        end

        set
      end

      # Generates a build for a C++ library wrapping the provided enum.
      def self.wrap_enum(enum_spec)
        build = CppSource::CppSourceSet.new(enum_spec.name)

        build.add_lib_header(define_enum(enum_spec))

        build
      end

      # Generates a build for a C++ library wrapping the provided scope.
      #
      # +scope+ describes all of the classes and other entities that will be
      # wrapped. These will all be put into a namespace named after the scope.
      def self.wrap_scope(scope)
        name_words = if scope.decorate_wrapped_name?
                       Cpp.decorate_name_words(scope.name_words)
                     else
                       scope.name_words
                     end
        name = name_words.map(&:downcase).join
        build = CppSource::CppSourceSet.new(name)

        scope.each do |scope_member|
          build << wrap(scope_member, scope: scope)
        end

        build
      end

      # The expression containing the call to the underlying wrapped function.
      def self.wrapped_function_call(func_spec)
        wrapped = func_spec.wrapped[:c]
        params = wrapped.params.map do |it|
          resolve_wrapped_param(func_spec, it)
        end
        wrapped_call = "#{wrapped.name}(#{params.join(', ')})"

        if func_spec.constructor?
          # TODO: constructor pointer handling needs to be more deliberate,
          # including support passing address of struct as arg and ownership
          # annotations
          "this->equivalent = #{wrapped_call}"
        elsif wrapper_captures_return?(func_spec)
          "return_val = #{wrapped_call}"
        elsif !func_spec.void_return?
          "return #{wrapped_call}"
        else
          wrapped_call
        end
      end

      # True if the wrapper for the given function needs to save the return
      # value from the wrapped function.
      def self.wrapper_captures_return?(func_spec)
        # true if the return value of the wrapped function must be converted
        # into a C++ type before it is returned
        convert_return = !func_spec.void_return? &&
                         func_spec.return_type != func_spec[:c].return_type

        func_spec[:c].error_rules.any?(&:use_return?) ||
          convert_return
      end
    end
  end
end
