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
        '*(self->equivalent)'
      elsif param_spec['value'] == EQUIVALENT_POINTER_KEYWORD
        'self->equivalent'
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
          from distutils.core import setup, Extension

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
      (@spec.classes + @spec.enums).flat_map do |item|
        object_name = "&#{item.snake_case_name}_type_object"
        previous_objects << object_name
        add_class_type_object(item, decref: previous_objects.reverse) do |line|
          block.call(line)
        end
        yield ''
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

    # Passes lines of C code to the given block which creates the methods and
    # type object for the given class in this module.
    def define_class_type_object(class_spec, &block)
      define_class_type_struct(class_spec) { |line| block.call(line) }
      yield ''

      class_method_defs = []
      class_spec.functions.each do |func_spec|
        define_function_wrapper(func_spec, &block)
        yield ''

        wrapper_name = function_wrapper_name(func_spec)
        class_method_defs << "  { \"#{func_spec.name}\","

        class_method_defs << "    ( PyCFunction ) #{wrapper_name},"
        class_method_defs << if func_spec.params.empty?
                               '    METH_NOARGS,'
                             else
                               '    METH_VARARGS,'
                             end

        class_method_defs << "    \"#{func_spec.doc.text}\"},"
      end

      snake_name = class_spec.snake_case_name
      yield "static PyMethodDef #{snake_name}_methods[] = {"
      class_method_defs.each { |method_def| block.call(method_def) }
      yield '  {NULL}'
      yield '};'
      yield ''

      yield "static PyTypeObject #{snake_name}_type_object = {"
      yield '  PyVarObject_HEAD_INIT( NULL, 0 )'
      yield "  .tp_name = \"#{@spec.name}.#{class_spec.name}\","
      yield "  .tp_doc = \"#{class_spec.doc.text}\","
      yield "  .tp_basicsize = sizeof( #{type_struct_name(class_spec)} ),"
      yield '  .tp_itemsize = 0,'
      yield '  .tp_flags = Py_TPFLAGS_DEFAULT,'
      yield "  .tp_new = #{snake_name}_new,"
      yield "  .tp_dealloc = ( destructor ) #{snake_name}_dealloc,"
      yield "  .tp_methods = #{snake_name}_methods"
      yield '};'
      yield ''
    end

    # Yields lines of C code to define the struct used to wrap objects of the
    # given class spec.
    def define_class_type_struct(class_spec)
      yield 'typedef struct {'
      yield '  PyObject_HEAD'
      yield "  struct #{class_spec.struct_name} *equivalent;"
      yield "} #{type_struct_name(class_spec)};"
    end

    # Passes lines of C code to the given block which creates the methods and
    # type object for the given enum in this module.
    def define_enum_type_object(enum_spec)
      snake_name = enum_spec.snake_case_name
      yield 'typedef struct {'
      yield '  PyObject_HEAD'
      yield "} #{type_struct_name(enum_spec)};"
      yield ''
      yield "static PyTypeObject #{snake_name}_type_object = {"
      yield '  PyVarObject_HEAD_INIT( NULL, 0 )'
      yield "  .tp_name = \"#{@spec.name}.#{enum_spec.name}\","
      yield "  .tp_doc = \"#{enum_spec.doc.text}\","
      yield "  .tp_basicsize = sizeof(#{type_struct_name(enum_spec)}),"
      yield '  .tp_itemsize = 0,'
      yield '  .tp_flags = Py_TPFLAGS_DEFAULT,'
      yield '  .tp_new = PyType_GenericNew,'
      yield '};'
      yield ''
    end

    # Defines the function that the python interpreter will call for the given
    # function spec.
    def define_function_wrapper(func_spec)
      name = function_wrapper_name(func_spec)
      owner_snake_name = func_spec.owner.snake_case_name
      type_struct_name = "#{owner_snake_name}_type_struct"

      if func_spec.destructor?
        yield 'static void'
        yield "#{name}( #{type_struct_name} *self ) {"
        yield "  #{func_spec.wrapped.call_from(PythonWrapper.new(func_spec))};"
        yield '  Py_TYPE( self )->tp_free( ( PyObject * ) self );'
      else
        yield 'static PyObject *'
        yield "#{name}( #{function_params(func_spec).join(', ')} ) {"

        function_locals(func_spec) { |declaration| yield "  #{declaration}" }

        if func_spec.constructor?
          yield "  self = ( #{type_struct_name} * ) type->tp_alloc( type, 0 );"
          yield '  // todo should check this for null?'
          yield ''
        end

        yield ''
        if func_spec.wrapped.is_a?(WrappedFunctionSpec)
          yield "  #{wrapped_call_expression(func_spec)};"
        else
          func_spec.wrapped.lines.each { |line| yield "  #{line}" }
        end

        yield "  #{return_statement(func_spec)}"
      end

      yield '}'
    end

    # Yields the full contents of the module source file to the provided block.
    def define_module(&block)
      yield '#define PY_SSIZE_T_CLEAN'
      yield '#include <Python.h>'

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
      yield ''
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
        define_enum_type_object(item) { |line| block.call(line) }
      end
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
      (@spec.classes + @spec.enums).flat_map do |item|
        yield "if ( PyType_Ready( &#{item.snake_case_name}_type_object ) < 0){"
        yield '  return NULL;'
        yield '}'
      end
    end

    # The name of the structure used to wrap objects of the given Named type.
    def type_struct_name(named_type)
      "#{named_type.snake_case_name}_type_struct"
    end

    # The expression containing the call to the underlying wrapped function.
    def wrapped_call_expression(func_spec)
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
