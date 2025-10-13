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

      # Creates a CppClass instance from a ClassSpec.
      def self.class_from_spec(spec)
        class_name = spec.upper_camel_case_name
        cls = Wrapture::CppSource::CppClass.new(class_name)
        cls.doc = spec.doc

        if spec.child?
          cls.parent_name = spec.parent_name
        elsif spec.exception?
          cls.parent_name = 'std::exception'
        end

        spec.method_specs.each do |meth_spec|
          func_name = meth_spec.upper_camel_case_name
          func = Wrapture::CppSource::CppFunction.new(func_name)
          return_spec = meth_spec.return_type
          func.return_type = Wrapture::CppSource::CppType.from_spec(return_spec)
          func.static = meth_spec.static?
          meth_spec.params.each do |param_spec|
            param_type = param_spec.type
            param_name = param_spec.name
            decl = Wrapture::CppSource::CppDeclaration.new(param_type,
                                                           name: param_name)
            func.params << decl
          end

          cls.member_functions << func
        end

        cls
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

      # Gives the filename used for the declaration of a given spec.
      def self.declaration_filename(spec)
        "#{spec.upper_camel_case_name}.hpp"
      end

      # The headers needed to declare the given class. This is a subset of the
      # spec includes, as the includes for things like calling wrapped functions
      # and invoking error handling are not needed for the declaration.
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
      def self.declare_class(class_spec)
        class_name = class_spec.upper_camel_case_name

        src = CppSource::CppSourceFile.new("#{class_name}.hpp")

        guard = header_guard(class_spec)
        src.puts("#ifndef #{guard}")
        src.puts("#define #{guard}")
        src.puts

        declaration_includes(class_spec).each do |inc|
          src.puts("#include <#{inc}>")
        end

        src.puts("namespace #{class_spec.namespace} {")
        src.puts

        src.declare(class_from_spec(class_spec))

        src.puts("  class #{class_name} #{ancestor_suffix(class_spec)} {")
        src.puts('  public:')

        wrapper = CToCppWrapper.new(class_spec)
        wrapper.declare do |line|
          src.puts(line)
        end

        src.puts("  }; /* class #{class_name} */")
        src.puts
        src.puts("} /* namespace #{class_spec.namespace} */")
        src.puts
        src.puts("#endif /* #{guard} */")

        src
      end

      # Generate a source file with the definition of a class.
      def self.define_class(class_spec)
        src = SourceFile.new("#{class_spec.name}.cpp")

        wrapper = CToCppWrapper.new(class_spec)
        wrapper.define do |line|
          src.puts(line)
        end

        src
      end

      # Generate a source file with the definition of an enumeration.
      def self.define_enum(enum_spec)
        src = SourceFile.new("#{enum_spec.name}.hpp")

        wrapper = CToCppWrapper.new(enum_spec)
        wrapper.define do |line|
          src.puts(line)
        end

        src
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

      # True if this instance's spec has separate definition and declaration
      # files.
      def self.forward_declared?(spec)
        !spec.is_a?(EnumSpec)
      end

      # The symbol to use for header guard checks.
      def self.header_guard(class_spec)
        "#{class_spec.screaming_snake_case_name}_HPP"
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
        used_param = func_spec.params.find { |p| p.name == param.value }

        if param.value == EQUIVALENT_STRUCT_KEYWORD
          class_struct(func_spec.owner)
        elsif param.value == EQUIVALENT_POINTER_KEYWORD
          class_struct_pointer(func_spec.owner)
        elsif param.value == '...'
          'variadic_args'
        elsif param_uses_equivalent?(func_spec, param)
          param_class = func_spec.owner.type(used_param.type)
          from = used_param.type
          to = param.c_type.to_s
          cast_equivalent(param_class, used_param.name, from, to)
        else
          param.value
        end
      end

      # Generates a build for a C++ library wrapping a class.
      def self.wrap_class(class_spec)
        set = CppSource::CppSourceSet.new(class_spec.name)

        set.add_lib_header(declare_class(class_spec))
        set.add_lib_source(define_class(class_spec))

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
        build = CppSource::CppSourceSet.new(scope.name)

        scope.each do |scope_member|
          build << wrap(scope_member)
        end

        build
      end
    end
  end
end
