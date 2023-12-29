# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021-2023 Joel E. Anderson
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
  # A wrapper that generates Python wrappers for given specs.
  class PythonWrapper
    # Generates the setup.py script and other supporting files for the
    # given spec. These can be used to package the files generated by
    # +write_source_files+. This is equivalent to instantiating a wrapper
    # with the spec and then calling write_setuptools_files on that.
    def self.write_spec_setuptools_files(spec, **kwargs)
      wrapper = new(spec)
      wrapper.write_setuptools_files(**kwargs)
    end

    # Generates C source files that form a Python extension, returning a list
    # of the files generated. This is equivalent to instantiating a wrapper
    # with the given spec, and then calling write_source_files on that.
    def self.write_spec_source_files(spec, **kwargs)
      wrapper = new(spec)
      wrapper.write_source_files(**kwargs)
    end

    # Creates a Python wrapper for a given spec.
    def initialize(spec)
      @spec = spec
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
        param_class.cast(used_param.name,
                         param_spec['type'],
                         used_param.type)
      else
        param_spec['value']
      end
    end

    # Generates the setup.py script and other supporting files for this
    # instance's spec. These can be used to package the files generated by
    # +write_source_files+.
    def write_setuptools_files(dir: Dir.pwd)
      unless @spec.is_a?(Scope)
        raise WrapError, 'only a scope can be used for setuptools generation'
      end

      libraries = @spec.libraries.map { |lib| "'#{lib}'" }.join(', ')

      File.open(File.join(dir, 'setup.py'), 'w') do |file|
        file.puts <<~SETUPTEXT
          from setuptools import setup, Extension

          #{@spec.name}_mod = Extension('#{@spec.name}',
                                        language = 'c',
                                        sources = ['#{@spec.name}.c'],
                                        libraries = [#{libraries}],
                                        library_dirs = ['.'], # todo handle this
                                        include_dirs = ['.']) # todo handle this

          setup(name = '#{@spec.name}',
                version = '1.0', # todo create a scope version number
                description = '#{@spec.doc.text}', # todo this should be better
                ext_modules = [#{@spec.name}_mod])
        SETUPTEXT
      end
    end

    # Generates C source files that form an extension module of Python with
    # the functionality of this instance's spec, returning a list of the
    # files generated. +dir+ specifies the directory that the files should
    # be written into. The default is the current working directory.
    def write_source_files(dir: Dir.pwd)
      unless @spec.is_a?(Scope)
        raise WrapError, 'only a scope can be used for module generation'
      end

      filename = "#{@spec.name}.c"

      File.open(File.join(dir, filename), 'w') do |file|
        define_module { |line| file.puts(line) }
      end

      filename
    end

    private

    # Yields lines of C code to add the type object for the given class to this
    # scope's module.
    def add_class_type_object(class_spec, decref: [])
      object_name = "#{class_spec.snake_case_name}_type_object"
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
        object_name = "&#{item.snake_case_name}_type_object"
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

    # True if the provided wrapped param spec can be cast to when used in this
    # function.
    def castable?(wrapped_param)
      param = @spec.params.find { |p| p.name == wrapped_param['value'] }

      !param.nil? &&
        !wrapped_param['type'].nil? &&
        @spec.owner.type?(param.type)
    end

    # Creates a Python object using a variable with the given name and type.
    def create_python_object(type, name)
      if type.name == 'int'
        "PyLong_FromLong(#{name})"
      elsif type.name == 'bool'
        "PyBool_FromLong(#{name})"
      else
        # TODO: default case
        ''
      end
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

      class_spec.functions.each do |func_spec|
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
      define_class_type_struct(class_spec) { |line| block.call(line) }
      yield ''

      # TODO: shouldn't be adding to the instance's list of functions
      if class_spec.struct&.members?
        class_spec.functions << member_constructor(class_spec)
      end

      unless class_spec.functions.any?(&:destructor?)
        class_spec.functions << default_destructor(class_spec)
      end

      class_spec.functions.each do |func_spec|
        define_function_wrapper(func_spec, &block)
        yield ''
      end

      # TODO: don't define these when not needed
      define_class_methods(class_spec, &block)
      yield ''

      # TODO: don't define these when not needed
      define_class_members(class_spec, &block)
      yield ''

      snake_name = class_spec.snake_case_name
      yield "static PyTypeObject #{snake_name}_type_object = {"
      yield '  PyVarObject_HEAD_INIT( NULL, 0 )'
      yield "  .tp_name = \"#{@spec.name}.#{class_spec.name}\","
      yield "  .tp_doc = \"#{class_spec.doc.text}\","
      yield "  .tp_basicsize = sizeof( #{type_struct_name(class_spec)} ),"
      yield '  .tp_itemsize = 0,'
      yield '  .tp_flags = Py_TPFLAGS_DEFAULT,'
      yield "  .tp_new = #{snake_name}_new,"
      yield "  .tp_dealloc = ( destructor ) #{snake_name}_dealloc,"
      yield "  .tp_methods = #{snake_name}_methods,"
      yield "  .tp_members = #{snake_name}_members"
      yield '};'
      yield ''
    end

    # Yields lines of C code to define the struct used to wrap objects of the
    # given class spec.
    def define_class_type_struct(class_spec)
      yield 'typedef struct {'
      yield '  PyObject_HEAD'
      class_spec.constants.each do |constant_spec|
        yield "  #{constant_spec.type} #{constant_spec.snake_case_name};"
      end
      yield "  #{equivalent_member_declaration(class_spec)}"
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

        val = element.fetch('value', i+1)
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

    # Defines the function that the python interpreter will call for the given
    # function spec.
    def define_function_wrapper(func_spec, &block)
      name = function_wrapper_name(func_spec)
      owner_snake_name = func_spec.owner.snake_case_name
      type_struct_name = "#{owner_snake_name}_type_struct"

      if func_spec.destructor?
        yield 'static void'
        yield "#{name}( #{type_struct_name} *self ) {"
        wrapped_call(func_spec, &block)
        yield '  Py_TYPE( self )->tp_free( ( PyObject * ) self );'
      else
        yield 'static PyObject *'
        yield "#{name}( #{function_params(func_spec).join(', ')} ) {"

        function_locals(func_spec) { |declaration| yield "  #{declaration}" }

        if func_spec.constructor?
          yield "  self = ( #{type_struct_name} * ) type->tp_alloc( type, 0 );"
          yield '  if( !self ) {'
          yield '    return NULL;'
          yield '  }'
          yield ''
          func_spec.owner.constants.each do |constant_spec|
            field_name = constant_spec.snake_case_name
            field_value = constant_spec.value
            yield "  self->#{field_name} = #{field_value};"
          end
          yield ''
        end

        wrapped_call(func_spec, &block)
        yield ''

        yield "  #{return_statement(func_spec)}"
      end

      yield '}'
    end

    # Yields the full contents of the module source file to the provided block.
    def define_module(&block)
      yield '#define PY_SSIZE_T_CLEAN'
      yield '#include <Python.h>'
      yield '#include <stddef.h>' # TODO: for offsetof(), only add if needed
      yield '#if PY_VERSION_HEX < 0x30C00F0  // under Python 3.12.0'
      yield '  #include <structmember.h> // for PyMemberDef'
      yield '  #define Py_T_INT T_INT'
      yield '  #define Py_READONLY READONLY'
      yield '#endif'

      @spec.definition_includes.each do |include_file|
        yield "#include <#{include_file}>"
      end

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

    # Yields lines of C code to define all type objects and supporting functions
    # for this module.
    def define_scope_type_objects(&block)
      yield "static struct PyModuleDef #{@spec.name}_module = {"
      yield '  PyModuleDef_HEAD_INIT,'
      yield "  .m_name = \"#{@spec.name}\","
      yield '  .m_doc = NULL,'
      yield '  .m_size = -1'
      yield '};'
      yield ''

      @spec.classes.each do |item|
        define_class_type_object(item) { |line| block.call(line) }
      end

      @spec.enums.each do |item|
        define_enum_constructor(item) { |line| block.call(line) }
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

    # Gives the flags used to define the python method for the given function.
    def function_flags(func_spec)
      flags = []

      flags << if func_spec.params.empty?
                 'METH_NOARGS'
               else
                 'METH_VARARGS'
               end

      flags << 'METH_CLASS' if func_spec.static?

      flags.join(' | ')
    end

    # Yields a declaration of each local variable used by the function.
    def function_locals(spec)
      if spec.constructor?
        owner_snake_name = spec.owner.snake_case_name
        type_struct_name = "#{owner_snake_name}_type_struct"
        yield "#{type_struct_name} *self;"
      end

      unless spec.void_return?
        if spec.return_type.name == 'bool'
          yield 'long return_val;'
        else
          yield "#{spec.return_type.variable('return_val')};"
        end
      end

      return if spec.params.empty?

      format_str = '"'
      param_names = []

      spec.params.each do |param_spec|
        format_str += 'i'
        param_names << param_spec.name
        yield "#{spec.resolve_type(param_spec.type)} #{param_spec.name};"
      end

      yield ''

      format_str += '"'
      parsed_args = "&#{param_names.join(', &')}"

      yield "if( !PyArg_ParseTuple( args, #{format_str}, #{parsed_args} ) ) {"
      yield '   return NULL;'
      yield '}'
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
        params << "#{type_struct_name} *self"

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
        "self->equivalent.#{name} = #{name};"
      end

      { 'name' => class_spec.name,
        'params' => class_spec.struct.members,
        'wrapped-code' => { 'lines' => assignments } }
    end

    # The Python member type symbol to use for this type, suitable for use with
    # the PyMemberDef.type struct field.
    def member_type(type_spec)
      case type_spec.name
      when 'int' then 'Py_T_INT'
        # TODO: need to finish filling this in
      else 'Py_T_OBJECT_EX'
      end
    end

    # The return statement used in this function's definition.
    def return_statement(func_spec)
      if func_spec.constructor?
        'return ( PyObject * ) self;'
      elsif func_spec.return_type.self_reference?
        'return self;'
      elsif func_spec.void_return?
        'Py_RETURN_NONE;'
      else
        "return #{create_python_object(func_spec.return_type, 'return_val')};"
      end
    end

    # Passes lines of C code to the given block which executes PyType_Ready
    # on each type in the module.
    def scope_types_ready
      @spec.classes.each do |item|
        yield "if ( PyType_Ready( &#{item.snake_case_name}_type_object ) < 0){"
        yield '  return NULL;'
        yield '}'
        yield ''
      end
    end

    # Gives a code snippet that accesses the equivalent struct from within the
    # class using the 'this' keyword.
    # Expected to be called while @spec is a FunctionSpec.
    def this_struct
      if @spec.owner.pointer_wrapper?
        '*(self->equivalent)'
      else
        'self->equivalent'
      end
    end

    # Gives a code snippet that accesses the equivalent struct pointer from
    # within the class using the 'this' keyword.
    # Expected to be called while @spec is a FunctionSpec.
    def this_struct_pointer
      "#{'&' unless @spec.owner.pointer_wrapper?}self->equivalent"
    end

    # The name of the structure used to wrap objects of the given Named type.
    def type_struct_name(named_type)
      "#{named_type.snake_case_name}_type_struct"
    end

    # Yields the lines to call the given function spec's wrapped code or
    # function.
    def wrapped_call(func_spec)
      if func_spec.wrapped.is_a?(WrappedFunctionSpec)
        yield "  #{wrapped_function_call(func_spec)};"
      elsif func_spec.wrapped.is_a?(WrappedCodeSpec)
        func_spec.wrapped.lines.each { |line| yield "  #{line}" }
      end
    end

    # The expression containing the call to the underlying wrapped function.
    def wrapped_function_call(func_spec)
      call = func_spec.wrapped.call_from(self.class.new(func_spec))

      if func_spec.constructor?
        "self->equivalent = #{call}"
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
