# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021 Joel E. Anderson
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

    # Creates a C++ wrapper for a given spec.
    def initialize(spec)
      @spec = spec
    end

    # Generates the setup.py script and other supporting files for this
    # instance's spec. These can be used to package the files generated by
    # +write_source_files+.
    def write_setuptools_files(dir: Dir.pwd)
      unless @spec.is_a?(Scope)
        raise WrapError, 'only a scope can be used for setuptools generation'
      end

      File.open(File.join(dir, 'setup.py'), 'w') do |file|
        file.puts <<~SETUPTEXT
          from distutils.core import setup, Extension

          #{@spec.name}_mod = Extension('#{@spec.name}',
                              sources = ['#{@spec.name}.c'])

          setup (name = '#{@spec.name}',
                 version = '1.0',
                 description = 'This is a demo package',
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

    # Passes lines of C code to the given block which creates the methods and
    # type object for the given class in this module.
    def define_class_type_object(class_spec)
      snake_name = class_spec.snake_case_name
      yield 'typedef struct {'
      yield '  PyObject_HEAD'
      yield "} #{snake_name}_type_struct;"
      yield ''
      yield "static PyTypeObject #{snake_name}_type_object = {"
      yield '  PyVarObject_HEAD_INIT(NULL, 0)'
      yield "  .tp_name = \"#{@spec.name}.#{class_spec.name}\","
      yield "  .tp_doc = \"#{class_spec.doc.text}\","
      yield "  .tp_basicsize = sizeof( #{snake_name}_type_struct ),"
      yield '  .tp_itemsize = 0,'
      yield '  .tp_flags = Py_TPFLAGS_DEFAULT,'
      yield '  .tp_new = PyType_GenericNew,'
      yield '};'
      yield ''
    end

    # Passes lines of C code to the given block which creates the methods and
    # type object for the given enum in this module.
    def define_enum_type_object(enum_spec)
      snake_name = enum_spec.snake_case_name
      yield 'typedef struct {'
      yield '  PyObject_HEAD'
      yield "} #{snake_name}_type_struct;"
      yield ''
      yield "static PyTypeObject #{snake_name}_type_object = {"
      yield '  PyVarObject_HEAD_INIT(NULL, 0)'
      yield "  .tp_name = \"#{@spec.name}.#{enum_spec.name}\","
      yield "  .tp_doc = \"#{enum_spec.doc.text}\","
      yield "  .tp_basicsize = sizeof(#{snake_name}_type_struct),"
      yield '  .tp_itemsize = 0,'
      yield '  .tp_flags = Py_TPFLAGS_DEFAULT,'
      yield '  .tp_new = PyType_GenericNew,'
      yield '};'
      yield ''
    end

    # Yields the full contents of the module source file to the provided block.
    def define_module(&block)
      yield '#define PY_SSIZE_T_CLEAN'
      yield '#include <Python.h>'
      yield ''
      define_scope_type_objects { |line| block.call(line) }
      yield 'PyMODINIT_FUNC'
      yield "PyInit_#{@spec.name}(void)"
      yield '{'
      yield '  PyObject *m;'
      yield ''
      scope_types_ready { |line| block.call("  #{line}") }
      yield ''
      yield "  m = PyModule_Create(&#{@spec.name}_module);"
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

    # Passes lines of C code to the given block which executes PyType_Ready
    # on each type in the module.
    def scope_types_ready
      (@spec.classes + @spec.enums).flat_map do |item|
        yield "if (PyType_Ready(&#{item.snake_case_name}_type_object) < 0){"
        yield '  return NULL;'
        yield '}'
      end
    end
  end
end
