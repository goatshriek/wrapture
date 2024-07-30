# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021-2024 Joel E. Anderson
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
  # A wrapper that generates C++ wrappers for given specs.
  class CppWrapper
    # Gives the filename used for the declaration of a given class spec.
    def self.declaration_filename(class_spec)
      "#{class_spec.name}.hpp"
    end

    # Gives each line of the declaration of a spec to the provided block
    # This is equivalent to instantiating a wrapper with the given spec, and
    # then calling declare on that.
    def self.declare_spec(spec, &block)
      wrapper = new(spec)
      wrapper.declare(&block)
    end

    # Gives each line of the definition of a spec to the provided block
    # This is equivalent to instantiating a wrapper with the given spec, and
    # then calling define on that.
    def self.define_spec(spec, &block)
      wrapper = new(spec)
      wrapper.define(&block)
    end

    # An array of source filenames that will be generated by this wrapper.
    def self.source_files(spec)
      wrapper = new(spec)
      wrapper.source_files
    end

    # Generates C++ source files, returning a list of the files generated. This
    # is equivalent to instantiating a wrapper with the given spec, and then
    # calling write_files on that.
    def self.write_spec_source_files(spec, **kwargs)
      wrapper = new(spec)
      wrapper.write_source_files(**kwargs)
    end

    # Creates a C++ wrapper for a given spec.
    def initialize(spec)
      @spec = spec
    end

    # Gives a list of ancestor classes of class spec, including a colon prefix,
    # if the class has ancestors. If not or if this wrapper is not for a class,
    # an empty string is returned instead.
    def ancestor_suffix
      if @spec.is_a?(ClassSpec) && @spec.child?
        ": public #{@spec.parent_name}"
      else
        ''
      end
    end

    # The name of the file that the declaration of this spec will be written to.
    # This may be the same as the definition filename for specs that are not
    # forward declared.
    def declaration_filename
      self.class.declaration_filename(@spec)
    end

    # Gives each line of the declaration to the provided block.
    #
    # Note that for some specs, the declaration is the same as the definition.
    # Use +forward_declared?+ to check if this is the case, which will be true
    # when the declaration and definition are different.
    def declare(&block)
      case @spec
      when ClassSpec
        declare_class(&block)
      when EnumSpec
        define_enum(&block)
      when FunctionSpec
        declare_function(&block)
      end
    end

    # Gives each line of the definition to the provided block.
    def define(&block)
      case @spec
      when ClassSpec
        define_class(&block)
      when EnumSpec
        define_enum(&block)
      when FunctionSpec
        define_function(&block)
      end
    end

    # The name of the file that the definition of this spec will be written to.
    # This may be the same as the declaration filename for specs that are not
    # forward declared.
    def definition_filename
      if forward_declared?
        "#{@spec.name}.cpp"
      else
        "#{@spec.name}.hpp"
      end
    end

    # True if this instance's spec has separate definition and declaration
    # files.
    def forward_declared?
      !@spec.is_a?(EnumSpec)
    end

    # Gives the symbol to use for header guard checks.
    def header_guard
      "#{@spec.name.upcase}_HPP"
    end

    # Gives an expression for using a given parameter.
    # Equivalent structs and pointers are resolved, as well as casts between
    # types if they are known within the scope of this function.
    # Expected to be called while @spec is a FunctionSpec.
    def resolve_param(param_spec)
      used_param = @spec.params.find { |p| p.name == param_spec['value'] }

      if param_spec['value'] == EQUIVALENT_STRUCT_KEYWORD
        this_struct
      elsif param_spec['value'] == EQUIVALENT_POINTER_KEYWORD
        this_struct_pointer
      elsif param_spec['value'] == '...'
        'variadic_args'
      elsif castable?(param_spec)
        param_class = @spec.owner.type(used_param.type)
        cast(param_class,
             used_param.name,
             param_spec['type'],
             used_param.type)
      else
        param_spec['value']
      end
    end

    # An array of source filenames that will be generated by this wrapper.
    def source_files
      if @spec.is_a?(Scope)
        @spec.flat_map do |spec|
          self.class.source_files(spec)
        end
      elsif forward_declared?
        [declaration_filename, definition_filename]
      else
        [definition_filename]
      end
    end

    # Generates a CMakeLists.txt file that can be used to build the files
    # generated by +write_source_files+.
    def write_cmake_files(dir: Dir.pwd)
      unless @spec.is_a?(Scope)
        raise WrapError, 'only a scope can be used for cmake generation'
      end

      filename = 'CMakeLists.txt'

      headers = []
      sources = []

      source_files.each do |source|
        headers.append(source) if source.end_with?('.hpp')
        sources.append(source) if source.end_with?('.cpp')
      end

      File.open(File.join(dir, filename), 'w') do |file|
        file.puts('cmake_minimum_required(VERSION 3.0.2)')
        file.puts("project(#{@spec.name})")
        file.puts

        header_list = "#{@spec.name.upcase}_HEADERS"
        file.puts("set(#{header_list}")
        headers.each do |source|
          file.puts("  #{source}")
        end
        file.puts(')')
        file.puts

        unless sources.empty?
          source_list = "#{@spec.name.upcase}_SOURCES"
          file.puts("set(#{source_list}")
          sources.each do |source|
            file.puts("  #{source}")
          end
          file.puts(')')
          file.puts

          lib_targets = []
          @spec.libraries.each do |lib|
            target_name = "#{@spec.name}_#{lib}"
            file.puts("find_library(LIB#{lib.upcase}_FOUND #{lib})")
            file.puts("add_library(#{target_name} SHARED IMPORTED)")
            file.puts("set_target_properties(#{target_name} PROPERTIES")
            file.puts("  IMPORTED_LOCATION ${LIB#{lib.upcase}_FOUND}")
            file.puts(')')
            file.puts

            lib_targets.append(target_name)
          end

          lib_deps = lib_targets.join(' ')
          file.puts("add_library(#{@spec.name} ${#{source_list}})")
          file.puts("target_link_libraries(#{@spec.name} PRIVATE #{lib_deps})")
          file.puts
        end

        file.puts('# todo add install command with headers')
      end

      [filename]
    end

    # Generates the C++ declaration file, returning the name of the file
    # generated.
    # +dir+ specifies the directory that the file should be written into. The
    # default is the current working directory.
    def write_declaration_file(dir: Dir.pwd)
      File.open(File.join(dir, declaration_filename), 'w') do |file|
        declare { |line| file.puts(line) }
      end

      declaration_filename
    end

    # Generates the C++ definition file, returning the name of the file
    # generated.
    # +dir+ specifies the directory that the file should be written into. The
    # default is the current working directory.
    def write_definition_file(dir: Dir.pwd)
      File.open(File.join(dir, definition_filename), 'w') do |file|
        self.class.define_spec(@spec) { |line| file.puts(line) }
      end

      definition_filename
    end

    # Generates C++ source files, returning a list of the files generated.
    # +dir+ specifies the directory that the files should be written into. The
    # default is the current working directory.
    def write_source_files(dir: Dir.pwd)
      if @spec.is_a?(Scope)
        @spec.flat_map do |spec|
          self.class.write_spec_source_files(spec, dir: dir)
        end
      elsif forward_declared?
        [write_declaration_file(dir: dir),
         write_definition_file(dir: dir)]
      else
        [write_definition_file(dir: dir)]
      end
    end

    private

    # True if this class should have a pointer constructor generated.
    def autogen_pointer_constructor?
      return false unless @spec.struct

      types = [EQUIVALENT_POINTER_KEYWORD, @spec.struct.pointer_declaration('')]

      @spec.functions.none? do |func|
        func.constructor? &&
          func.params.length == 1 &&
          types.include?(func.params[0].type.name)
      end
    end

    # Returns a cast of an instance of this class with the provided name to the
    # specified type. Optionally the from parameter may hold the type of the
    # instance, either a reference or a pointer.
    def cast(class_spec, var_name, to, from = name)
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
      end
    end

    # True if the provided wrapped param spec can be cast to when used in this
    # function.
    def castable?(wrapped_param)
      param = @spec.params.find { |p| p.name == wrapped_param['value'] }

      !param.nil? &&
        !wrapped_param['type'].nil? &&
        @spec.owner.type?(param.type)
    end

    # Returns a list of FunctionSpecs describing all of the functions generated
    # for a ClassSpec. This includes both those listed in the original
    # ClassSpec, as well as those auto-generated by the library.
    def class_functions
      functions = @spec.functions.dup

      if autogen_pointer_constructor?
        spec_hash = pointer_constructor_hash
        functions << FunctionSpec.new(spec_hash, @spec, constructor: true)
      end

      if @spec.struct&.members?
        spec_hash = member_constructor_hash
        functions << FunctionSpec.new(spec_hash, @spec, constructor: true)
      end

      if @spec.factory?
        functions << FunctionSpec.new(factory_constructor_hash, @spec)
      end

      functions
    end

    # A list of includes common to both a class definition and declaration.
    def common_includes(class_spec)
      includes = []

      if class_spec.child?
        parent_spec = class_spec.type(class_spec.parent_name)
        unless parent_spec.nil?
          includes << self.class.declaration_filename(parent_spec)
        end
      end

      class_spec.functions.each do |func_spec|
        func_spec.params.each do |param_spec|
          param_type = class_spec.type(param_spec.type)
          unless param_type.nil?
            includes << self.class.declaration_filename(param_type)
          end
        end
      end

      includes
    end

    # A list of includes needed for the definition of the class.
    def declaration_includes
      @spec.declaration_includes.concat(common_includes(@spec))
    end

    # Gives each line of the declaration of a ClassSpec to the provided block.
    def declare_class
      yield "#ifndef #{header_guard}"
      yield "#define #{header_guard}"
      yield ''

      unless @spec.declaration_includes.empty?
        declaration_includes.each { |inc| yield "#include <#{inc}>" }
        yield ''
      end

      yield "namespace #{@spec.namespace} {"
      yield ''

      @spec.documentation { |line| yield "  #{line}" }
      yield "  class #{@spec.name} #{ancestor_suffix} {"
      yield '  public:'

      unless @spec.constants.empty?
        @spec.constants.each do |constant|
          declare_constant(constant) { |line| yield "    #{line}" }
        end
        yield ''
      end

      class_functions.each do |function|
        self.class.declare_spec(function) { |line| yield "    #{line}" }
      end

      if @spec.equivalent_member?
        yield ''
        yield "    #{equivalent_member_declaration}"
      end

      yield '  };' # end of class
      yield ''
      yield '}' # end of namespace
      yield ''
      yield "#endif /* #{header_guard} */"
    end

    # Gives each line of the declaration of the given ConstantSpec.
    def declare_constant(constant_spec, &block)
      constant_spec.doc&.format_as_doxygen(max_line_length: 76, &block)
      yield "static const #{constant_spec.type.variable(constant_spec.name)};"
    end

    # Gives each line of the declaration of a FunctionSpec to the provided
    # block.
    def declare_function(&block)
      @spec.doc.format_as_doxygen(max_line_length: 76) do |line|
        block.call(line)
      end

      modifier_prefix = if @spec.static?
                          'static '
                        elsif @spec.virtual?
                          'virtual '
                        elsif @spec.destructor?
                          '~'
                        else
                          ''
                        end

      block.call("#{modifier_prefix}#{function_declaration_signature(@spec)};")
    end

    # Gives each line of the definition of a ClassSpec to the provided block.
    def define_class
      yield "#include <#{@spec.name}.hpp>"
      definition_includes.each { |inc| yield "#include <#{inc}>" }

      yield ''
      yield "namespace #{@spec.namespace} {"

      yield unless @spec.constants.empty?
      @spec.constants.each do |const|
        yield "  #{define_constant(const, @spec.name)};"
      end

      class_functions.each do |function|
        yield ''
        self.class.define_spec(function) { |line| yield "  #{line}" }
      end

      yield ''
      yield '}' # end of namespace
    end

    # Gives each line of the definition of a ConstantSpec in a given class to
    # the provided block.
    def define_constant(constant_spec, class_name)
      expanded_name = "#{class_name}::#{constant_spec.name}"
      "const #{constant_spec.type} #{expanded_name} = #{constant_spec.value}"
    end

    # Gives each line of the definition of a EnumSpec to the provided block.
    def define_enum
      indent = 0

      yield "#ifndef #{header_guard}"
      yield "#define #{header_guard}"
      yield ''

      @spec.definition_includes.each do |include_file|
        yield "#include <#{include_file}>"
      end

      if @spec.namespace?
        yield ''
        yield "namespace #{@spec.namespace} {"
        yield ''
        indent += 2
      end

      @spec.doc.format_as_doxygen(max_line_length: 76) do |line|
        yield "#{' ' * indent}#{line}"
      end

      yield "#{' ' * indent}enum class #{@spec.name} {"
      indent += 2

      elements = @spec.elements
      @spec.elements[0...-1].each do |element|
        enum_element_doc(element) { |line| yield "#{' ' * indent}#{line}" }
        yield "#{' ' * indent}#{enum_element_definition(element)},"
      end

      enum_element_doc(elements.last) { |line| yield "#{' ' * indent}#{line}" }
      yield "#{' ' * indent}#{enum_element_definition(elements.last)}"

      indent -= 2
      yield "#{' ' * indent}};"
      yield
      yield '}' if @spec.namespace?
      yield
      yield "#endif /* #{header_guard} */"
    end

    # Gives each line of the definition of a FunctionSpec to the provided
    # block.
    def define_function
      @spec.definable!

      signature = function_definition_signature(@spec)

      yield "#{signature} #{initializer_suffix}{"

      function_locals(@spec) { |declaration| yield "  #{declaration}" }
      yield ''

      if @spec.variadic?
        yield "  va_start( variadic_args, #{@spec.params[-2].name} );"
        yield ''
      end

      if @spec.wrapped.is_a?(WrappedFunctionSpec)
        yield "  #{wrapped_call_expression};"
      else
        @spec.wrapped.lines.each { |line| yield "  #{line}" }
      end

      if @spec.wrapped.error_check?
        yield ''
        @spec.wrapped.error_check(return_val: return_variable) do |line|
          yield "  #{line}"
        end
      end

      yield '  va_end( variadic_args );' if @spec.variadic?

      yield "  #{return_statement}"

      yield '}'
    end

    # A list of includes needed for the definition of the class.
    def definition_includes
      includes = @spec.definition_includes
      includes.concat(common_includes(@spec))

      @spec.scope.overloads(@spec).map do |overload|
        includes.append("#{overload.name}.hpp")
      end

      includes
    end

    # The definition of an enum element.
    def enum_element_definition(element)
      if element.key?('value')
        "#{element['name']} = #{element['value']}"
      else
        element['name']
      end
    end

    # Calls the given block once for each line of the documentation for an
    # element.
    def enum_element_doc(element, &block)
      doc = Comment.new(element.fetch('doc', nil))
      doc.format_as_doxygen(max_line_length: 74) { |line| block.call(line) }
    end

    # The declaration of the equivalent member of this class.
    def equivalent_member_declaration
      if @spec.pointer_wrapper?
        "#{@spec.struct.pointer_declaration('equivalent')};"
      else
        "#{@spec.struct.declaration('equivalent')};"
      end
    end

    # An expression for a field of the equivalent member of this class.
    def equivalent_member_field(field_name)
      "this->equivalent#{@spec.pointer_wrapper? ? '->' : '.'}#{field_name}"
    end

    # A spec hash for a factory constructor for this class.
    def factory_constructor_hash
      factory_lines = []
      line_prefix = ''
      @spec.scope.overloads(@spec).each do |overload|
        check = overload.struct.rules_check('equivalent')
        factory_lines << "#{line_prefix}if( #{check} ) {"
        factory_lines << "  return new #{overload.name}( equivalent );"
        line_prefix = '} else '
      end

      factory_lines << "#{line_prefix}{"
      factory_lines << "  return new #{@spec.name}( equivalent );"
      factory_lines << '}'

      { 'name' => "new#{@spec.name}",
        'static' => true,
        'params' => [{ 'name' => 'equivalent',
                       'type' => 'equivalent-struct-pointer' }],
        'wrapped-code' => { 'lines' => factory_lines },
        'return' => { 'type' => "#{@spec.name} *" } }
    end

    # The parameter list for the function declaration.
    def function_declaration_param_list(func_spec)
      if func_spec.params.empty?
        'void'
      else
        func_spec.params.map do |param|
          sig = param.type.resolve(func_spec).variable(param.name)

          if param.default_value?
            sig += ' = '
            sig += if param.type.name == 'const char *'
                     "\"#{param.default_value}\""
                   elsif param.type.name.end_with?('char')
                     "'#{param.default_value}'"
                   else
                     param.default_value.to_s
                   end
          end

          sig
        end.join(', ')
      end
    end

    # The signature of a function in the declaration.
    def function_declaration_signature(func_spec)
      if func_spec.constructor? || func_spec.destructor?
        "#{func_spec.name}( #{function_declaration_param_list(func_spec)} )"
      else
        return_type = func_spec.resolved_return
        return_type.return_expression(func_spec, func_name: func_spec.name)
      end
    end

    # The parameter list for the function definition.
    def function_definition_param_list(func_spec)
      if func_spec.params?
        func_spec.params.map do |param|
          param.type.resolve(func_spec).variable(param.name)
        end.join(', ')
      else
        'void'
      end
    end

    # The signature of a function in the definition.
    def function_definition_signature(func_spec)
      func_name = qualified_function_name(func_spec)
      if func_spec.constructor? || func_spec.destructor?
        "#{func_name}( #{function_definition_param_list(func_spec)} )"
      else
        return_type = func_spec.resolved_return
        return_type.return_expression(func_spec, func_name: func_name)
      end
    end

    # Yields a declaration of each local variable used by the function.
    def function_locals(spec)
      yield 'va_list variadic_args;' if spec.variadic?

      if spec.capture_return?
        wrapped_type = spec.resolve_type(spec.wrapped.return_val_type)
        yield "#{wrapped_type.variable('return_val')};"
      end
    end

    # The suffix to add to a function definition for initializers, if any exist.
    def initializer_suffix
      return '' if @spec.initializers.empty?

      if @spec.initializers.first['delegate']
        params = @spec.initializers.first['values'].join(', ')
        return ": #{@spec.owner.name}( #{params} ) "
      end

      expressions = @spec.initializers.map do |initializer|
        "#{initializer['name']}( #{initializer['values'].join(', ')} )"
      end

      ": #{expressions.join(', ')} "
    end

    # A spec hash for a member constructor for this class.
    def member_constructor_hash
      assignments = @spec.struct.members.map do |member|
        "#{equivalent_member_field(member['name'])} = #{member['name']};"
      end

      { 'name' => @spec.name,
        'params' => @spec.struct.members,
        'wrapped-code' => { 'lines' => assignments } }
    end

    # A spec hash for a pointer constructor for this class.
    def pointer_constructor_hash
      assignments = if @spec.pointer_wrapper?
                      ['this->equivalent = equivalent;']
                    else
                      @spec.struct.members.map do |member|
                        lvalue = equivalent_member_field(member['name'])
                        "#{lvalue} = equivalent->#{member['name']};"
                      end
                    end

      spec_hash = { 'name' => @spec.name,
                    'params' => [{ 'name' => 'equivalent',
                                   'type' => 'equivalent-struct-pointer' }],
                    'wrapped-code' => { 'lines' => assignments } }
      if @spec.parent_provides_initializer?
        spec_hash['initializers'] = [{ 'name' => @spec.parent_name,
                                       'values' => ['equivalent'] }]
      end

      spec_hash
    end

    # The name of the given function with its class name, if it exists.
    def qualified_function_name(function_spec)
      if function_spec.owner.is_a?(ClassSpec)
        if function_spec.destructor?
          "#{function_spec.owner.name}::~#{function_spec.name}"
        else
          "#{function_spec.owner.name}::#{function_spec.name}"
        end
      else
        function_spec.name
      end
    end

    # A function to use to create the return value of a function.
    def return_cast(value)
      if @spec.return_type == @spec.wrapped.return_val_type
        value
      elsif @spec.return_overloaded?
        "new#{@spec.return_type.name.chomp('*').strip} ( #{value} )"
      else
        @spec.resolved_return.cast_expression(value)
      end
    end

    # The return statement used in this function's definition.
    def return_statement
      if @spec.return_type.self_reference?
        'return *this;'
      elsif @spec.return_type.name != 'void' && !@spec.returns_call_directly?
        'return return_val;'
      else
        ''
      end
    end

    # The name of the variable holding the return value.
    def return_variable
      if @spec.constructor?
        'this->equivalent'
      else
        'return_val'
      end
    end

    # Gives a code snippet that accesses the equivalent struct from within the
    # class using the 'this' keyword.
    # Expected to be called while @spec is a FunctionSpec.
    def this_struct
      if @spec.owner.pointer_wrapper?
        '*(this->equivalent)'
      else
        'this->equivalent'
      end
    end

    # Gives a code snippet that accesses the equivalent struct pointer from
    # within the class using the 'this' keyword.
    # Expected to be called while @spec is a FunctionSpec.
    def this_struct_pointer
      "#{'&' unless @spec.owner.pointer_wrapper?}this->equivalent"
    end

    # The expression containing the call to the underlying wrapped function.
    def wrapped_call_expression
      call = @spec.wrapped.call_from(self)

      if @spec.constructor?
        "this->equivalent = #{call}"
      elsif @spec.wrapped.error_check?
        "return_val = #{call}"
      elsif @spec.returns_call_directly?
        "return #{return_cast(call)}"
      else
        call
      end
    end
  end
end
