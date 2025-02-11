# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021-2025 Joel E. Anderson
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
  # A wrapper that generates Python wrappers for C code.
  class CToPythonWrapper
    # Mapping of basic types to their Py_T counterparts.
    MEMBER_TYPE_MAP = {
      'byte' => 'Py_T_BYTE',
      'char' => 'Py_T_CHAR',
      'short' => 'Py_T_SHORT',
      'int' => 'Py_T_INT',
      'long' => 'Py_T_LONG',
      'long long' => 'Py_T_LONGLONG',
      'unsigned char' => 'Py_T_UBYTE',
      'unsigned short' => 'Py_T_USHORT',
      'unsigned int' => 'Py_T_UINT',
      'unsigned long' => 'Py_T_ULONG',
      'unsigned long long' => 'Py_T_ULONGLONG',
      'size_t' => 'Py_T_PYSSIZET',
      'float' => 'Py_T_FLOAT',
      'double' => 'Py_T_DOUBLE',
      'bool' => 'Py_T_BOOL',
      # no current wrapture construct for Py_T_STRING_INPLACE
      'string' => 'Py_T_STRING'
    }.freeze

    # Mapping of types to their PyArg_ParseTuple format string.
    TYPE_FORMAT_UNIT_MAP = {
      'byte' => 'b',
      'char' => 'b',
      'short' => 'h',
      'int' => 'i',
      'long' => 'l',
      'long long' => 'k',
      'unsigned char' => 'B',
      'unsigned short' => 'H',
      'unsigned int' => 'I',
      'unsigned long' => 'L',
      'unsigned long long' => 'K',
      'size_t' => 'n',
      'float' => 'f',
      'double' => 'd',
      'bool' => 'p',
      'const char *' => 's',
      'string' => 's'
    }.freeze

    # Gives the name of the type object instance for a given class.
    def self.type_object_name(class_spec)
      "#{class_spec.snake_case_name}_type_object"
    end

    # Gives the name of the type struct for a given class.
    def self.type_struct_name(class_spec)
      "#{class_spec.snake_case_name}_type_struct"
    end

    # Creates a Python wrapper for a given spec.
    def initialize(spec)
      @spec = spec
    end

    # Yields the full contents of the module source file to the provided block.
    def define_module(&block)
      yield ''
      define_scope_type_objects { |line| block.call(line) }
      yield 'PyMODINIT_FUNC'
      yield "PyInit_#{@spec.name}( void )"
      yield '{'
      yield '  PyObject *m;'
      yield ''
      scope_types_ready { |line| block.call("  #{line}") }
      yield "  m = PyModule_Create( &#{@spec.name}_module );"
      yield '  if( !m ){'
      yield '    return NULL;'
      yield '  }'
      yield ''
      add_scope_type_objects { |line| block.call("  #{line}") }
      yield '  return m;'
      yield '}'
    end

    # Gives an expression for using a given parameter.
    # Equivalent structs and pointers are resolved, as well as casts between
    # types if they are known within the scope of this function.
    # Expected to be called while @spec is a FunctionSpec.
    def resolve_param(param_spec)
      used_param = @spec.params.find { |p| p.name == param_spec['value'] }

      if param_spec['value'] == EQUIVALENT_STRUCT_KEYWORD
        this_struct(@spec.owner)
      elsif param_spec['value'] == EQUIVALENT_POINTER_KEYWORD
        this_struct_pointer(@spec.owner)
      elsif param_spec['value'] == '...'
        'variadic_args'
      elsif castable?(param_spec)
        param_class = @spec.owner.type(used_param.type)
        cast(param_class, used_param.name, param_spec['type'])
      else
        param_spec['value']
      end
    end

    # A string containing the invocation of the given action.
    def action_block(class_spec, action_spec)
      return unless action_spec.value?

      exception_type = action_spec.type
      exception_class = class_spec.scope.type(exception_type)
      type_struct = self.class.type_struct_name(exception_class)
      type_object = self.class.type_object_name(exception_class)
      callable = "(PyObject *) &#{type_object}"

      yield 'PyObject *exception_instance;'
      yield "#{type_struct} *real_self;"
      yield ''
      yield "exception_instance = PyObject_CallObject( #{callable}, NULL );"
      self_cast = runtime_type_cast(exception_class, 'exception_instance')
      yield "real_self = #{self_cast};"
      this_struct = this_struct_pointer(exception_class, var_name: 'real_self')
      yield "#{this_struct} = return_val;"
      yield 'PyErr_SetRaisedException( exception_instance );'
      yield 'return NULL;'
    end

    # Yields lines of C code to add the type object for the given class to this
    # scope's module.
    def add_class_type_object(class_spec, decref: [])
      object_name = self.class.type_object_name(class_spec)
      yield "Py_INCREF(&#{object_name});"
      add_params = "m, \"#{class_spec.name}\", (PyObject *) &#{object_name}"
      yield "if (PyModule_AddObject(#{add_params}) < 0) {"
      decref.each { |obj| yield "  Py_DECREF( #{obj} );" }
      yield '  return NULL;'
      yield '}'
    end

    # Passes lines of C code to the given block which adds type objects for
    # all classes and enums in this module.
    def add_scope_type_objects(&block)
      previous_objects = ['m']
      @spec.classes.each do |item|
        object_name = "&#{self.class.type_object_name(item)}"
        previous_objects << object_name
        add_class_type_object(item, decref: previous_objects.reverse) do |line|
          block.call(line)
        end
        yield ''
      end

      @spec.enums.each do |enum_spec|
        snake_name = enum_spec.snake_case_name
        block.call("Py_DECREF( add_#{snake_name}_enum_to_module( m ) );")
      end
      yield ''
    end

    # Get the name of the type object for the given class's base, if one exists.
    def base_type_object(class_spec)
      if class_spec.child? && class_spec.parent_spec
        return "(&#{self.class.type_object_name(class_spec.parent_spec)})"
      end

      return '(( PyTypeObject *) PyExc_Exception)' if class_spec.exception?

      nil
    end

    # Returns a cast of an instance of this class with the provided name to the
    # specified type.
    def cast(class_spec, var_name, to)
      struct = "struct #{class_spec.struct.name}"

      if [EQUIVALENT_STRUCT_KEYWORD, struct].include?(to)
        "#{'*' if class_spec.pointer_wrapper?}#{var_name}->equivalent"
      elsif [EQUIVALENT_POINTER_KEYWORD, "#{struct} *"].include?(to)
        "#{'&' unless class_spec.pointer_wrapper?}#{var_name}->equivalent"
      end
    end

    # True if the provided wrapped param spec can be cast to when used in this
    # function. Expects @spec to be a function spec when called.
    def castable?(wrapped_param)
      param = @spec.params.find { |p| p.name == wrapped_param['value'] }

      !param.nil? &&
        !wrapped_param['type'].nil? &&
        @spec.owner.type?(param.type)
    end

    # Returns a list of FunctionSpecs describing all of the functions generated
    # for a ClassSpec. This includes both those listed in the original
    # ClassSpec, as well as those auto-generated for Python.
    def class_functions(class_spec)
      functions = class_spec.functions.dup

      functions << member_constructor(class_spec) if class_spec.struct&.members?

      unless functions.any?(&:destructor?)
        functions << default_destructor(class_spec)
      end

      unless functions.any?(&:constructor?)
        functions << default_constructor(class_spec)
      end

      functions
    end

    # The name of the class, fully qualified with the module it is part of.
    def class_module_name(class_spec)
      "#{class_spec.scope.name}.#{class_spec.name}"
    end

    # The functions of the given spec where functions that are overloads of each
    # other are grouped together. Functions that are overloaded are represented
    # as an array of function specs. Functions that are not overloaded are in an
    # array by themselves.
    def class_function_groups(class_spec)
      groups = []

      funcs = class_functions(class_spec)
      groups.append(funcs.select(&:constructor?))
      groups.append(funcs.select(&:destructor?))
      methods = funcs.select do |func_spec|
        !func_spec.constructor? && !func_spec.destructor?
      end.group_by(&:name).values

      groups.concat(methods)
    end

    # Creates a Python object using a variable with the given name and type.
    def create_python_object(type, name)
      case type.name
      when 'int'
        "PyLong_FromLong(#{name})"
      when 'bool'
        "PyBool_FromLong(#{name})"
      when 'const char *'
        "PyUnicode_FromString(#{name})"
      else
        # TODO: default case
        "// TODO default case for #{type.name}, #{name}"
      end
    end

    # Yields a declaration of a factory constructor for the given class.
    #
    # A factory constructor creates an instance of a class based on a struct
    # that is overloaded.
    def declare_factory_constructor(class_spec)
      param_decl = "struct #{class_spec.struct.name} *equivalent"
      yield "PyObject * new_#{class_spec.name}( #{param_decl} );"
    end

    # The default constructor for python classes if one is not given or derived.
    def default_constructor(class_spec)
      spec_hash = { 'name' => "#{class_spec.name}_new",
                    'wrapped-code' => { 'lines' => [] } }

      FunctionSpec.new(spec_hash, class_spec, constructor: true)
    end

    # The default destructor for python classes if one is not given.
    def default_destructor(class_spec)
      spec_hash = { 'name' => "#{class_spec.name}_dealloc",
                    'wrapped-code' => { 'lines' => [] } }

      FunctionSpec.new(spec_hash, class_spec, destructor: true)
    end

    # Passes lines of C code to the given block which define the members of the
    # given class as an array of PyMemberDef structures.
    def define_class_members(class_spec)
      snake_name = class_spec.snake_case_name
      yield "static PyMemberDef #{snake_name}_members[] = {"

      class_spec.constants.each do |constant_spec|
        yield "  { .name = \"#{constant_spec.name}\","
        yield "    .type = #{member_type(constant_spec.type)},"

        offset_struct = type_struct_name(class_spec)
        offset_field = constant_spec.snake_case_name
        yield "    .offset = offsetof( #{offset_struct}, #{offset_field} ),"
        yield '    .flags = Py_READONLY,'
        yield "    .doc = \"#{constant_spec.doc.text}\" },"
      end

      yield '  {NULL}'
      yield '};'
    end

    # Passes lines of C code to the given block which define the methods of the
    # given class as an array of PyMethodDef structures.
    def define_class_methods(class_spec)
      snake_name = class_spec.snake_case_name
      yield "static PyMethodDef #{snake_name}_methods[] = {"

      # class_spec.functions.each do |func_spec|
      # class_function_groups(class_spec).map(&:first).each do |func_spec|
      class_spec.method_specs.each do |func_spec|
        wrapper_name = function_wrapper_name(func_spec)
        yield "  { .ml_name = \"#{func_spec.name}\","
        yield "    .ml_meth = ( PyCFunction ) #{wrapper_name},"
        yield "    .ml_flags = #{function_flags(func_spec)},"
        yield "    .ml_doc = \"#{func_spec.doc.text}\" },"
      end

      yield '  {NULL}'
      yield '};'
    end

    # Passes lines of C code to the given block which creates the methods and
    # type object for the given class in this module.
    def define_class_type_object(class_spec, &block)
      yield ''

      class_function_groups(class_spec).each do |func_group|
        if func_group.length == 1
          define_function_wrapper(class_spec, func_group[0], &block)
        else
          define_function_group_wrapper(class_spec, func_group, &block)
        end
        yield ''
      end

      # TODO: don't define these when not needed
      define_class_methods(class_spec, &block)
      yield ''

      # TODO: don't define these when not needed
      define_class_members(class_spec, &block)
      yield ''

      snake_name = class_spec.snake_case_name
      yield "static PyTypeObject #{self.class.type_object_name(class_spec)} = {"
      yield '  PyVarObject_HEAD_INIT( NULL, 0 )'
      yield "  .tp_name = \"#{@spec.name}.#{class_spec.name}\","
      yield "  .tp_doc = \"#{class_spec.doc.text}\","
      yield "  .tp_basicsize = sizeof( #{type_struct_name(class_spec)} ),"
      yield '  .tp_itemsize = 0,'
      flags = 'Py_TPFLAGS_DEFAULT'
      flags += ' | Py_TPFLAGS_BASETYPE' if class_spec.parent?
      yield "  .tp_flags = #{flags},"
      yield "  .tp_new = #{snake_name}_new,"
      yield "  .tp_dealloc = ( destructor ) #{snake_name}_dealloc,"
      yield "  .tp_methods = #{snake_name}_methods,"

      if base_type_object(class_spec) && !runtime_class?(class_spec)
        yield "  .tp_base = #{base_type_object(class_spec)},"
      end

      yield "  .tp_members = #{snake_name}_members"
      yield '};'
      yield ''
    end

    # Yields lines of C code to define the struct used to wrap objects of the
    # given class spec.
    def define_class_type_struct(class_spec)
      yield 'typedef struct {'
      if class_spec.child?
        parent_spec = class_spec.parent_spec
        unless parent_spec.nil?
          yield "  #{self.class.type_struct_name(parent_spec)} super;"
        end
      else
        yield '  PyObject_HEAD'
      end

      class_spec.constants.each do |constant_spec|
        yield "  #{constant_spec.type} #{constant_spec.snake_case_name};"
      end
      if class_spec.equivalent_member?
        yield "  #{equivalent_member_declaration(class_spec)}"
      end
      yield "} #{type_struct_name(class_spec)};"
    end

    # Passes lines of C code to the given block which define a function to
    # create the enum and add it to a supplied module object.
    # TODO: need to add NULL checks
    def define_enum_constructor(enum_spec)
      snake_name = enum_spec.snake_case_name
      yield "PyObject * add_#{snake_name}_enum_to_module( PyObject *m ) {"
      yield '  PyObject *element_dict;'
      yield '  PyObject *element_name;'
      yield '  PyObject *element_value;'
      yield '  PyObject *enum_name;'
      yield '  PyObject *call_args;'
      yield '  PyObject *call_kwargs;'
      yield '  PyObject *kw_name;'
      yield '  PyObject *kw_value;'
      yield '  PyObject *enum_mod;'
      yield '  PyObject *enum_type;'
      yield '  PyObject *new_enum;'
      yield ''
      yield '  // setting up the elements of the enumeration'
      yield '  element_dict = PyDict_New();'
      enum_spec.elements.each_with_index do |element, i|
        yield "  element_name = PyUnicode_FromString( \"#{element['name']}\" );"

        val = element.fetch('value', i + 1)
        yield "  element_value = PyLong_FromLong( #{val} );"

        yield '  PyObject_SetItem( element_dict, element_name, element_value );'
        yield '  Py_DECREF( element_name );'
        yield '  Py_DECREF( element_value );'
        yield ''
      end
      yield ''
      yield '  // building the positional arguments to enum.Enum'
      yield "  enum_name = PyUnicode_FromString( \"#{enum_spec.name}\" );"
      yield '  call_args = PyTuple_Pack( 2, enum_name, element_dict );'
      yield '  Py_DECREF( enum_name );'
      yield '  Py_DECREF( element_dict );'
      yield ''
      yield '  // building the keyword argument to enum.Enum'
      yield '  call_kwargs = PyDict_New();'
      yield '  kw_name = PyUnicode_FromString( "module" );'
      yield '  kw_value = PyModule_GetNameObject( m );'
      yield '  PyObject_SetItem( call_kwargs, kw_name, kw_value );'
      yield '  Py_DECREF( kw_name );'
      yield '  Py_DECREF( kw_value );'
      yield ''
      yield '  // importing enum and getting the Enum type from it'
      yield '  enum_mod = PyImport_ImportModule( "enum" );'
      yield '  enum_type = PyObject_GetAttrString( enum_mod, "Enum" );'
      yield '  Py_DECREF( enum_mod );'
      yield ''
      yield '  // making the call to enum.Enum to create the new type'
      yield '  new_enum = PyObject_Call( enum_type, call_args, call_kwargs );'
      yield '  Py_DECREF( enum_type );'
      yield '  Py_DECREF( call_args );'
      yield '  Py_DECREF( call_kwargs );'
      yield ''
      yield '  // adding the new type to the module'
      yield "  PyModule_AddObject( m, \"#{enum_spec.name}\", new_enum );"
      yield '  return new_enum;'
      yield '}'
    end

    # Passes lines of C code to the given block which define a function to
    # create an exception class.
    def define_exception_constructor(class_spec)
      snake_name = class_spec.snake_case_name
      yield "PyObject * create_#{snake_name}_exception( void ){"
      # TODO: actually implement
      qualified_name = class_module_name(class_spec)
      yield "  return PyErr_NewException( \"#{qualified_name}\", NULL, NULL );"
      yield '}'
    end

    # Defines a function that parses and validates parameters of a function.
    def define_function_arg_parser(func_spec, name = nil)
      yield 'static int'
      name = "parse_#{function_wrapper_name(func_spec)}" if name.nil?
      signature_declarations = []
      parse_args = []
      parse_locals = []

      func_spec.params.each do |param_spec|
        param_type_spec = func_spec.resolve_type(param_spec.type)
        param_type = if func_spec.owner.scope.type?(param_type_spec)
                       "#{self.class.type_struct_name(param_type_spec)} **"
                     else
                       "#{param_type_spec} *"
                     end
        signature_declarations << "#{param_type} #{param_spec.name}"

        parse_args << if param_type_spec == 'bool'
                        parse_locals << { name: "#{param_spec.name}_int",
                                          decl: "int #{param_spec.name}_int;",
                                          param: param_spec.name }
                        "&#{param_spec.name}_int"
                      else
                        param_spec.name
                      end
      end
      wrapped_args = signature_declarations.join(', ')
      yield "#{name}( PyObject *args, PyObject *kwds, #{wrapped_args} ) {"
      parse_locals.each { |local| yield local[:decl] }
      unless parse_locals.empty?
        yield 'int parse_result;'
        yield ''
      end

      format_str = "\"#{function_args_format(func_spec)}\""
      params = parse_args.join(', ')
      parse_call = "PyArg_ParseTuple( args, #{format_str}, #{params} )"

      if parse_locals.empty?
        yield "  return #{parse_call};"
      else
        yield "  parse_result = #{parse_call};"
        parse_locals.each do |local|
          yield "  *#{local[:param]} = #{local[:name]};"
        end
        yield '  return parse_result;'
      end
      yield '}'
    end

    # Defines a function that determines which function in the provided group to
    # call based on the parameters, and then calls it in the python interpreter.
    def define_function_group_wrapper(class_spec, func_group, &block)
      base_name = function_wrapper_name(func_group[0])
      no_args = nil

      func_group.each_with_index do |func_spec, i|
        wrapper_name = "#{base_name}_#{i}"

        no_args = wrapper_name unless func_spec.params?

        define_function_wrapper(class_spec, func_spec, wrapper_name, &block)
        yield ''
      end

      yield 'static PyObject *'
      yield "#{base_name}( #{function_params(func_group[0]).join(', ')} ) {"
      yield '  int parse_result;'
      func_group.each_with_index do |func_spec, i|
        function_param_locals(func_spec, "_#{i}") do |stmt|
          yield "  #{stmt}".rstrip
        end
      end
      yield ''

      func_group.each_with_index do |func_spec, i|
        next unless func_spec.params?

        wrapper_name = "#{base_name}_#{i}"
        parser_name = "parse_#{base_name}_#{i}"
        parsed_args = "&#{func_spec.param_names.join("_#{i}, &")}_#{i}"
        yield "  parse_result = #{parser_name}( args, kwds, #{parsed_args} );"
        yield '  if( parse_result ){'
        yield "    return #{wrapper_name}( type, args, kwds );"
        yield '  }'
        yield ''
      end

      if no_args
        yield '  // TODO check to make sure there are no args for this call'
        yield "  return #{no_args}( type, args, kwds );"
      end

      yield '  // TODO throw an error for no overload found'
      yield '}'
    end

    # Defines the function that the python interpreter will call for the given
    # function spec. If +name+ is provided it will be used as the name of the
    # function instead of deriving it from the spec.
    def define_function_wrapper(class_spec, func_spec, name = nil, &block)
      name = function_wrapper_name(func_spec) if name.nil?

      owner_snake_name = func_spec.owner.snake_case_name
      type_struct_name = "#{owner_snake_name}_type_struct"

      if func_spec.destructor?
        yield 'static void'
        yield "#{name}( #{type_struct_name} *self ) {"
        wrapped_call(func_spec, &block)
        yield '  Py_TYPE( self )->tp_free( ( PyObject * ) self );'
      else
        if func_spec.params?
          define_function_arg_parser(func_spec, "parse_#{name}", &block)
          yield ''
        end
        yield 'static PyObject *'
        yield "#{name}( #{function_params(func_spec).join(', ')} ) {"

        function_locals(func_spec) { |declaration| yield "  #{declaration}" }
        yield ''

        if func_spec.params?
          parsed_args = "&#{func_spec.param_names.join(', &')}"
          yield "  if( !parse_#{name}( args, NULL, #{parsed_args} ) ){"
          yield '    return NULL;'
          yield '  }'
          yield ''
        end

        if func_spec.constructor?
          yield "  self = ( #{type_struct_name} * ) type->tp_alloc( type, 0 );"
          yield '  if( !self ) {'
          yield '    return NULL;'
          yield '  }'

          yield '' unless func_spec.owner.constants.empty?

          func_spec.owner.constants.each do |constant_spec|
            field_name = constant_spec.snake_case_name
            field_value = constant_spec.value
            yield "  self->#{field_name} = #{field_value};"
          end
          yield ''
        elsif runtime_class?(func_spec.owner)
          self_cast = runtime_type_cast(func_spec.owner, 'runtime_self')
          yield "  self = #{self_cast};"
        end

        wrapped_call(func_spec, &block)
        yield ''

        if func_spec.wrapped.error_check?
          error_check(class_spec, func_spec.wrapped,
                      return_val: 'return_val') do |line|
            yield "  #{line}"
          end
          yield ''
        end

        yield "  #{return_statement(func_spec)}"
      end

      yield '}'
    end

    # Yields lines of C code to define all type objects and supporting functions
    # for this module.
    def define_scope_type_objects(&block)
      @spec.classes.each do |item|
        define_class_type_struct(item) { |line| block.call(line) }
        yield ''
        yield "static PyTypeObject #{self.class.type_object_name(item)};"
        yield ''
      end

      yield ''

      @spec.classes.select(&:factory?).each do |item|
        declare_factory_constructor(item, &block)
        yield ''
      end

      @spec.classes.each do |item|
        define_class_type_object(item) { |line| block.call(line) }
      end

      @spec.enums.each do |item|
        define_enum_constructor(item) { |line| block.call(line) }
        yield ''
      end

      @spec.classes.select(&:factory?).each do |item|
        define_factory_constructor(item, &block)
        yield ''
      end
    end

    # The declaration of the equivalent member of this class.
    def equivalent_member_declaration(class_spec)
      if class_spec.pointer_wrapper?
        "#{class_spec.struct.pointer_declaration('equivalent')};"
      else
        "#{class_spec.struct.declaration('equivalent')};"
      end
    end

    # Yields a definition of a factory constructor for the given class.
    #
    # A factory constructor creates an instance of a class based on a struct
    # that is overloaded.
    def define_factory_constructor(class_spec)
      param_decl = "struct #{class_spec.struct.name} *equivalent"
      yield "PyObject * new_#{class_spec.name}( #{param_decl} ){"
      yield '  PyTypeObject *type;'
      yield '  PyObject *obj;'
      yield ''
      line_prefix = ''
      class_spec.scope.overloads(class_spec).each do |overload|
        check = overload.struct.rules_check('equivalent')
        yield "  #{line_prefix}if( #{check} ) {"
        yield "    type = &#{self.class.type_object_name(overload)};"
        struct_type = self.class.type_struct_name(overload)
        yield "    #{struct_type} *new_#{struct_type};"
        struct_name = "new_#{struct_type}"
        alloc_call = "(#{struct_type} *) type->tp_alloc( type, 0 )"
        yield "    #{struct_name} = #{alloc_call};"
        yield "    #{this_struct_pointer(overload,
                                         var_name: struct_name)} = equivalent;"
        yield "    obj = (PyObject *) new_#{struct_type};"
        line_prefix = '} else '
      end

      yield "  #{line_prefix}{"
      yield "    type = &#{self.class.type_object_name(class_spec)};"
      struct_type = self.class.type_struct_name(class_spec)
      yield "    #{struct_type} *new_#{struct_type};"
      alloc_call = "(#{struct_type} *) type->tp_alloc( type, 0 )"
      yield "    new_#{struct_type} = #{alloc_call};"
      yield "    new_#{struct_type}->equivalent = equivalent;"
      yield "    obj = (PyObject *) new_#{struct_type};"
      yield '  }'
      yield ''
      yield '  return obj;'
      yield '}'
    end

    # Yields each line of the error check and any actions taken for the given
    # wrapped function. If this function does not have any error check defined,
    # then this function returns without yielding anything.
    #
    # +return_val+ is used as the replacement for a return value signified by
    # the use of RETURN_VALUE_KEYWORD in the spec. If not specified it defaults
    # to +'return_val'+.
    def error_check(class_spec, wrapped_func, return_val: 'return_val')
      return unless wrapped_func.error_check?

      checks = wrapped_func.error_rules.map do |rule|
        rule.check(return_val: return_val)
      end

      yield "if( #{checks.join(' && ')} ){"
      action_block(class_spec, wrapped_func.error_action) do |line|
        yield "  #{line}"
      end
      yield '}'
    end

    # The format string for PyArg_ParseTuple for the given function.
    def function_args_format(func_spec)
      required_formats = func_spec.required_params.map do |param_spec|
        param_format(func_spec, param_spec)
      end

      optional_formats = func_spec.optional_params.map do |param_spec|
        param_format(func_spec, param_spec)
      end

      "#{required_formats.join}|#{optional_formats.join}"
    end

    # Gives the flags used to define the python method for the given function.
    def function_flags(func_spec)
      flags = []

      flags << if func_spec.params.empty?
                 'METH_NOARGS'
               else
                 'METH_VARARGS'
               end

      flags << 'METH_STATIC' if func_spec.static?

      flags.join(' | ')
    end

    # Yields a declaration of each local variable used by the function.
    def function_locals(func_spec, &block)
      if func_spec.constructor? || runtime_class?(func_spec.owner)
        owner_snake_name = func_spec.owner.snake_case_name
        type_struct_name = "#{owner_snake_name}_type_struct"
        yield "#{type_struct_name} *self;"
      end

      if !func_spec.void_return? || func_spec.wrapped.use_return?
        effective_return = func_spec.wrapped.return_val_type
        if effective_return.name == 'void'
          effective_return = func_spec.return_type
        end
        effective_return = func_spec.resolve_type(effective_return)

        if effective_return.name == 'bool'
          yield 'long return_val;'
        else
          yield "#{effective_return} return_val;"
        end
      end

      function_param_locals(func_spec, &block)
    end

    # Yields a declaration of each local variable needed for params by a
    # function.
    def function_param_locals(spec, suffix = '')
      return unless spec.params?

      spec.params.each do |param_spec|
        param_type_spec = spec.resolve_type(param_spec.type)
        param_type = if spec.owner.scope.type?(param_type_spec)
                       "#{self.class.type_struct_name(param_type_spec)} *"
                     else
                       param_type_spec.to_s
                     end
        yield "#{param_type} #{param_spec.name}#{suffix};"
      end

      yield '' unless spec.optional_params.empty?

      spec.optional_params.each do |param_spec|
        assignment = "#{param_spec.name} = "
        assignment += if param_spec.type.name == 'const char *'
                        "\"#{param_spec.default_value}\""
                      elsif param_spec.type.name.end_with?('char')
                        "'#{param_spec.default_value}'"
                      else
                        param_spec.default_value.to_s
                      end
        yield "#{assignment};"
      end
    end

    # A list of parameters for the given function's wrapper.
    def function_params(func_spec)
      owner_snake_name = func_spec.owner.snake_case_name
      type_struct_name = "#{owner_snake_name}_type_struct"

      params = []

      if func_spec.constructor?
        params << 'PyTypeObject *type'
        params << 'PyObject *args'
        params << 'PyObject *kwds'
      else
        params << if runtime_class?(func_spec.owner)
                    'void *runtime_self'
                  else
                    "#{type_struct_name} *self"
                  end

        params << if func_spec.params.empty?
                    'PyObject *Py_UNUSED( ignored )'
                  else
                    'PyObject *args'
                  end
      end

      params
    end

    # The name of the function that will be defined to wrap the given function.
    def function_wrapper_name(func_spec)
      owner_snake_name = func_spec.owner.snake_case_name

      if func_spec.constructor?
        "#{owner_snake_name}_new"
      elsif func_spec.destructor?
        "#{owner_snake_name}_dealloc"
      else
        "#{owner_snake_name}_#{func_spec.name}"
      end
    end

    # A constructor to create a class based on its equivalent struct members.
    def member_constructor(class_spec)
      spec_hash = member_constructor_hash(class_spec)
      FunctionSpec.new(spec_hash, class_spec, constructor: true)
    end

    # A spec hash for a member constructor for this class.
    def member_constructor_hash(class_spec)
      assignments = class_spec.struct.members.map do |member|
        name = member['name']
        "#{this_struct(class_spec)}.#{name} = #{name};"
      end

      { 'name' => class_spec.name,
        'params' => class_spec.struct.members,
        'wrapped-code' => { 'lines' => assignments } }
    end

    # The Python member type symbol to use for this type, suitable for use with
    # the PyMemberDef.type struct field.
    def member_type(type_spec)
      MEMBER_TYPE_MAP.fetch(type_spec.name, 'Py_T_OBJECT_EX')
    end

    # The format string for PyArg_ParseTuple for the given function parameter.
    def param_format(func_spec, param_spec)
      key = func_spec.resolve_type(param_spec.type).to_s
      TYPE_FORMAT_UNIT_MAP.fetch(key, 'O')
    end

    # The return statement used in this function's definition.
    def return_statement(func_spec)
      if func_spec.constructor?
        'return ( PyObject * ) self;'
      elsif func_spec.return_type.self_reference?
        'return self;'
      elsif func_spec.void_return?
        'Py_RETURN_NONE;'
      elsif func_spec.return_overloaded?
        overload_function = "new_#{func_spec.return_type.name.chomp('*').strip}"
        "return #{overload_function}( return_val );"
      else
        return_value = create_python_object(func_spec.return_type, 'return_val')
        if return_value.empty?
          'return;'
        else
          "return #{return_value};"
        end
      end
    end

    # True if some aspects of the class need to be defined at runtime.
    #
    # Exception classes are one example of this case, as the Exception class and
    # its associated type information is not available until runtime.
    def runtime_class?(class_spec)
      class_spec.exception?
    end

    # A cast of a runtime type to the class type struct.
    def runtime_type_cast(class_spec, var_name)
      type_struct_name = self.class.type_struct_name(class_spec)
      type_object = base_type_object(class_spec)
      real_self = "((intptr_t)#{var_name}) + #{type_object}->tp_basicsize"
      "( #{type_struct_name} * )( #{real_self} )"
    end

    # Passes lines of C code to the given block which executes PyType_Ready
    # on each type in the module.
    def scope_types_ready
      @spec.classes.each do |item|
        type_object = "#{item.snake_case_name}_type_object"

        if runtime_class?(item)
          yield "#{type_object}.tp_base = #{base_type_object(item)};"
          base_size = "#{base_type_object(item)}->tp_basicsize"
          self_size = "sizeof( #{self.class.type_struct_name(item)}"
          yield "#{type_object}.tp_basicsize =  #{base_size}+ #{self_size} );"
        end

        yield "if ( PyType_Ready( &#{item.snake_case_name}_type_object ) < 0){"
        yield '  return NULL;'
        yield '}'
        yield ''
      end
    end

    # Gives a code snippet that accesses the equivalent struct from within the
    # class using the given variable name.
    def this_struct(class_spec, var_name: 'self')
      # TODO: handle if parent struct isn't used
      parent_in_scope = class_spec.scope.type?(class_spec.parent_name)
      name = if class_spec.child? && parent_in_scope
               "#{var_name}->super.equivalent"
             else
               "#{var_name}->equivalent"
             end

      if class_spec.pointer_wrapper?
        "*(#{name})"
      else
        name
      end
    end

    # Gives a code snippet that accesses the equivalent struct pointer from
    # within the class using the given variable name.
    def this_struct_pointer(class_spec, var_name: 'self')
      # TODO: handle if parent struct isn't used
      parent_in_scope = class_spec.scope.type?(class_spec.parent_name)
      name = if class_spec.child? && parent_in_scope
               "#{var_name}->super.equivalent"
             else
               "#{var_name}->equivalent"
             end

      if class_spec.pointer_wrapper?
        name
      else
        "&(#{name})"
      end
    end

    # The name of the structure used to wrap objects of the given Named type.
    def type_struct_name(named_type)
      "#{named_type.snake_case_name}_type_struct"
    end

    # Yields the lines to call the given function spec's wrapped code or
    # function.
    def wrapped_call(func_spec)
      if func_spec.wrapped.is_a?(CFunctionSpec)
        yield "  #{wrapped_function_call(func_spec)};"
      elsif func_spec.wrapped.is_a?(CCodeSpec)
        func_spec.wrapped.lines.each { |line| yield "  #{line}" }
      end
    end

    # The expression containing the call to the underlying wrapped function.
    def wrapped_function_call(func_spec)
      call = func_spec.wrapped.call_from(self.class.new(func_spec))

      if func_spec.constructor?
        "#{this_struct_pointer(func_spec.owner)} = #{call}"
      elsif func_spec.wrapped.error_check? || !func_spec.void_return?
        "return_val = #{call}"
      # elsif func_spec.returns_call_directly?
      #  "return #{return_cast(func_spec, call)}"
      else
        call
      end
    end
  end
end
