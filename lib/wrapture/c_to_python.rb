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

    # Gives a code snippet that accesses the equivalent struct pointer from
    # within the class using the given variable name.
    def self.class_struct_pointer(class_spec, var_name: 'self')
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

    # Defines an array of PyMemberDef structures for a given class spec.
    def self.class_members_declaration(class_spec)
      # yield "static PyMemberDef #{snake_name}_members[] = {"

      # class_spec.constants.each do |constant_spec|
      #   yield "  { .name = \"#{constant_spec.name}\","
      #   yield "    .type = #{member_type(constant_spec.type)},"

      #   offset_struct = type_struct_name(class_spec)
      #   offset_field = constant_spec.snake_case_name
      #   yield "    .offset = offsetof( #{offset_struct}, #{offset_field} ),"
      #   yield '    .flags = Py_READONLY,'
      #   yield "    .doc = \"#{constant_spec.doc.text}\" },"
      # end

      # yield '  {NULL}'
      # yield '};'

      snake_name = class_spec.snake_case_name
      members = ['{NULL}']

      Wrapture::CSource::CDeclaration.new('PyMemberDef',
                                          "#{snake_name}_members[]",
                                          attributes: ['static'],
                                          value: members)
    end

    # Defines a PyTypeObject struct for the given class.
    def self.class_type_object_declaration(class_spec)
      snake_name = class_spec.snake_case_name
      type_name = "#{class_spec.scope.name}.#{class_spec.name}"
      flags = 'Py_TPFLAGS_DEFAULT'
      flags += ' | Py_TPFLAGS_BASETYPE' if class_spec.parent?

      members = [
        'PyVarObject_HEAD_INIT( NULL, 0 )',
        ".tp_name = \"#{type_name}\"",
        ".tp_doc = \"#{class_spec.doc.text}\"",
        ".tp_basicsize = sizeof( #{type_struct_name(class_spec)} )",
        '.tp_itemsize = 0',
        ".tp_flags = #{flags}",
        ".tp_new = #{snake_name}_new",
        ".tp_dealloc = ( destructor ) #{snake_name}_dealloc",
        ".tp_methods = #{snake_name}_methods",
        ".tp_members = #{snake_name}_members"
      ]

      if base_type_object(class_spec) && !runtime_class?(class_spec)
        members << ".tp_base = #{base_type_object(class_spec)}"
      end

      Wrapture::CSource::CDeclaration.new('PyTypeObject',
                                          type_object_name(class_spec),
                                          attributes: ['static'],
                                          value: members)
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
        members << "#{constant_spec.type} #{constant_spec.snake_case_name};"
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
      module_fields = ['.m_base = PyModuleDef_HEAD_INIT',
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

        next unless class_spec.factory?

        # TODO: do we need this forward declaration?
        src << factory_constructor(class_spec).declaration
      end

      scope.classes.select(&:factory?).each do |class_spec|
        src << factory_constructor(class_spec)
      end

      src.puts('// START LEGACY WRAPPER CODE')
      wrapper = CToPythonWrapper.new(scope)
      wrapper.define_module do |line|
        src.puts(line)
      end
      src.puts('// END LEGACY WRAPPER CODE')

      scope.classes.each do |class_spec|
        src << class_members_declaration(class_spec)
        src << class_type_object_declaration(class_spec)
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
      type = Wrapture::CSource::CStruct.from_spec(class_spec.struct)
      if class_spec.pointer_wrapper?
        type = Wrapture::CSource::CPointer.new(type)
      end

      Wrapture::CSource::CDeclaration.new(type, 'equivalent')
    end

    # The factory constructor for an overloaded struct.
    def self.factory_constructor(class_spec)
      name = "new_#{class_spec.name}"
      struct_type = Wrapture::CSource::CStruct.from_spec(class_spec.struct)
      pointer_type = Wrapture::CSource::CPointer.new(struct_type)
      params = [Wrapture::CSource::CDeclaration.new(pointer_type, 'equivalent')]
      return_type = Wrapture::CSource::CPointer.new('PyObject')
      func = Wrapture::CSource::CFunction.new(name, params: params,
                                                    return_type: return_type)

      type_object_type = Wrapture::CSource::CPointer.new('PyTypeObject')
      func.declare(type_object_type, 'type')
      func.declare(return_type, 'obj')

      cond = nil
      class_spec.scope.overloads(class_spec).each do |overload|
        cond = if cond.nil?
                 func.if(overload.struct.rules_check('equivalent'))
               else
                 cond.else_if(overload.struct.rules_check('equivalent'))
               end

        blk = cond.if_block
        blk.puts("type = &#{type_object_name(overload)};")
        struct_type = type_struct_name(overload)
        blk.puts("#{struct_type} *new_#{struct_type};")
        struct_name = "new_#{struct_type}"
        alloc_call = "(#{struct_type} *) type->tp_alloc( type, 0 )"
        blk.puts("#{struct_name} = #{alloc_call};")
        equiv = class_struct_pointer(overload, var_name: struct_name)
        blk.puts("#{equiv} = equivalent;")
        blk.puts("obj = (PyObject *) new_#{struct_type};")
      end

      cond.else do |blk|
        blk.puts("type = &#{type_object_name(class_spec)};")
        struct_type = type_struct_name(class_spec)
        blk.puts("#{struct_type} *new_#{struct_type};")
        alloc_call = "(#{struct_type} *) type->tp_alloc( type, 0 )"
        blk.puts("new_#{struct_type} = #{alloc_call};")
        blk.puts("new_#{struct_type}->equivalent = equivalent;")
        blk.puts("obj = (PyObject *) new_#{struct_type};")
      end

      func.puts('return obj;')
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
