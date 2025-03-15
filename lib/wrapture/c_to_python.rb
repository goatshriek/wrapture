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
  # A collection of wrappers for generating Python wrappers for C code.
  module CToPython
    # Adds the type object for a class within a module's init function.
    def self.add_class_object(src, class_spec, fail_label)
      object_name = type_object_name(class_spec)
      src.puts("Py_INCREF( &#{object_name} );")
      add_params = "m, \"#{class_spec.name}\", ( PyObject * ) &#{object_name}"
      src.if("PyModule_AddObject( #{add_params} ) < 0") do |blk|
        blk.puts("goto #{fail_label};")
      end

      src
    end

    # Adds the type object for an enum within a module's init function.
    def self.add_enum_object(src, enum_spec, fail_label)
      snake_name = enum_spec.snake_case_name
      src.if("add_#{snake_name}_enum_to_module( m ) == -1") do |blk|
        blk.puts("goto #{fail_label};")
      end
      src
    end

    # Adds code to a module init function to add the class and enum type objects
    # to the corresponding module.
    def self.add_module_objects(src, scope)
      scope.classes.each do |class_spec|
        object_name = type_object_name(class_spec)
        fail_label = "fail_add_#{object_name}"
        add_class_object(src, class_spec, fail_label)
        src.add_fail_label(fail_label, "Py_DECREF( &#{object_name} );")
      end

      scope.enums.each do |enum_spec|
        fail_label = "fail_add_#{enum_spec.snake_case_name}"
        add_enum_object(src, enum_spec, fail_label)
        src.add_fail_label(fail_label)
      end

      src
    end

    # The struct used to to wrap objects of the class.
    def self.class_type_struct(class_spec)
      members = []

      if class_spec.child?
        parent_spec = class_spec.parent_spec
        unless parent_spec.nil?
          members << "#{type_struct_name(parent_spec)} super"
        end
      else
        members << 'PyObject_HEAD'
      end

      class_spec.constants.each do |constant_spec|
        members << "#{constant_spec.type} #{constant_spec.snake_case_name}"
      end

      if class_spec.equivalent_member?
        members << equivalent_member_declaration(class_spec)
      end

      CSource::CStruct.new(members: members,
                           typedef: type_struct_name(class_spec))
    end

    # Declares the module definition struct (PyModuleDef) in a source file for
    # a scope.
    def self.declare_module_struct(src, scope)
      module_name = scope.snake_case_name
      module_struct = CSource::CStruct.new(name: 'PyModuleDef')
      module_fields = ['PyModuleDef_HEAD_INIT',
                       ".m_name = \"#{module_name}\"",
                       '.m_doc = NULL',
                       '.m_size = -1']
      src.declare(module_struct, "#{module_name}_module",
                  attributes: ['static'],
                  value: module_fields)
    end

    # Generates a source file with the definition of a module for a scope.
    def self.define_module(scope)
      src = CSource::CSourceFile.new("#{scope.name}.c")

      src.puts('#define PY_SSIZE_T_CLEAN')
      src.include('Python.h')

      # TODO: only include this if it's needed
      src.include('stddef.h', comment: 'for offsetof()')

      scope.definition_includes.each { |inc| src.include(inc) }

      declare_module_struct(src, scope)

      scope.classes.each do |class_spec|
        src << class_type_struct(class_spec)
        src.declare('PyTypeObject', type_object_name(class_spec),
                    attributes: ['static'])
      end

      wrapper = CToPythonWrapper.new(scope)
      wrapper.define_module do |line|
        src.puts(line)
      end

      define_module_init(src, scope)
    end

    # Add the definition of the module init function to a source file.
    def self.define_module_init(src, scope)
      return_type = CSource::CType.new('PyMODINIT_FUNC')
      init_func = CSource::CFunction.new("PyInit_#{scope.snake_case_name}",
                                         return_type: return_type)
      init_func.puts('PyObject *m;')
      finalize_module_types(init_func, scope)
      init_func.puts("m = PyModule_Create( &#{scope.snake_case_name}_module );")
      init_func.if('!m') { |block| block.puts('goto fail;') }
      init_func.add_fail_label('fail', 'return NULL;')
      add_module_objects(init_func, scope)
      init_func.puts('return m;')

      src << init_func
    end

    # The declaration of the equivalent member of this class.
    def self.equivalent_member_declaration(class_spec)
      type = CStruct.from_spec(class_spec.struct)
      if class_spec.pointer_wrapper?
        # class_spec.struct.pointer_declaration('equivalent')
        type = CPointer.new(type)
        # else
        # class_spec.struct.declaration('equivalent')
        # decl
      end

      CDeclaration.new(type, 'equivalent')
    end

    # Performs runtime setup of the types in a module and calls PyType_Ready so
    # to register them.
    def self.finalize_module_types(blk, scope)
      scope.classes.each do |cls|
        py_type = type_object_name(cls)

        if runtime_class?(cls)
          blk.puts("#{py_type}.tp_base = #{base_type_object(cls)};")
          base_size = "#{base_type_object(cls)}->tp_basicsize"
          self_size = "sizeof( #{type_struct_name(cls)}"
          blk.puts("#{py_type}.tp_basicsize =  #{base_size} + #{self_size} );")
        end

        blk.if("PyType_Ready( &#{py_type} ) < 0") do |fail_blk|
          fail_blk.puts('return NULL;')
        end
      end
    end

    # True if some aspects of the class need to be defined at runtime.
    #
    # Exception classes are one example of this case, as the Exception class and
    # its associated type information is not available until runtime.
    def self.runtime_class?(class_spec)
      class_spec.exception?
    end

    # Gives the name of the type object instance for a given class.
    def self.type_object_name(class_spec)
      "#{class_spec.snake_case_name}_type_object"
    end

    # Get the name of the type object for the given class's base, if one exists.
    def self.base_type_object(class_spec)
      if class_spec.child? && class_spec.parent_spec
        return "(&#{type_object_name(class_spec.parent_spec)})"
      end

      return '(( PyTypeObject *) PyExc_Exception)' if class_spec.exception?

      nil
    end

    # Gives the name of the type struct for a given class.
    def self.type_struct_name(class_spec)
      "#{class_spec.snake_case_name}_type_struct"
    end

    # Generates a build for a Python library wrapping the provided scope.
    #
    # +scope+ describes all of the classes and other entities that will be
    # wrapped. These will all be put into a namespace named after the scope.
    def self.wrap_scope(scope)
      build = PythonBuild.new(scope.name)

      build.add_module_source(define_module(scope))

      scope.libraries.each do |lib|
        build.add_link(lib)
      end

      build
    end
  end
end
