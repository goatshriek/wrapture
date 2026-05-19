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
    # A collection of wrappers for generating Python wrappers for C code.
    module CToPython
      extend Wrapper

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

      # Adds code to a module init function to add the class and enum type
      # objects to the corresponding module.
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

      # The parameters used for a type allocator.
      #
      # This matches the signature of the +tp_new+ member of PyTypeObject, which
      # has type +newfunc+.
      def self.allocator_params
        type_object_ptr = CSource::CPointer.new('PyTypeObject')
        pyobject_ptr = CSource::CPointer.new('PyObject')

        [CSource::CDeclaration.new(type_object_ptr, 'subtype'),
         CSource::CDeclaration.new(pyobject_ptr, 'args'),
         CSource::CDeclaration.new(pyobject_ptr, 'kwds')]
      end

      # The format string to use for argument parsing functions, such as
      # +PyArg_ParseTuple+.
      def self.arg_parse_format(func_spec)
        required_formats = func_spec.required_params.map do |param_spec|
          param_format(func_spec, param_spec)
        end

        optional_formats = func_spec.optional_params.map do |param_spec|
          param_format(func_spec, param_spec)
        end

        "#{required_formats.join}|#{optional_formats.join}"
      end

      # Get the name of the type object for the given class's base, if one
      # exists.
      def self.base_type_object(class_spec)
        if class_spec.child? && class_spec.parent_spec
          return "(&#{type_object_name(class_spec.parent_spec)})"
        end

        return '(( PyTypeObject *) PyExc_Exception)' if class_spec.exception?

        nil
      end

      # Returns a cast of the equivalent member of an instance of the given
      # class with the given name to the given type.
      def self.cast_equivalent(class_spec, var_name, to)
        pointer_wrapper = C.equivalent_type(class_spec).is_a?(CSource::CPointer)
        if [EQUIVALENT_STRUCT_KEYWORD,
            C.equivalent_struct(class_spec)].include?(to)
          "#{'*' if pointer_wrapper}#{var_name}->equivalent"
        elsif [EQUIVALENT_POINTER_KEYWORD,
               C.equivalent_pointer(class_spec)].include?(to)
          "#{'&' unless pointer_wrapper}#{var_name}->equivalent"
        end
      end

      # Declares an array of PyMemberDef structures for a given class spec.
      def self.class_members_declaration(class_spec)
        snake_name = class_spec.snake_case_name
        members = class_spec.constants.map do |constant_spec|
          offset_struct = type_struct_name(class_spec)
          offset_field = constant_spec.snake_case_name
          init = [".name = \"#{constant_spec.name}\"",
                  ".type = #{member_type(constant_spec.type)}",
                  ".offset = offsetof( #{offset_struct}, #{offset_field} )",
                  '.flags = Py_READONLY']

          unless constant_spec.doc.empty?
            init << ".doc = \"#{constant_spec.doc.text}\""
          end

          CSource::CDeclaration.new('PyMemberDef', nil, value: init)
        end
        members << '{NULL}'

        CSource::CDeclaration.new('PyMemberDef',
                                  "#{snake_name}_members[]",
                                  attributes: ['static'],
                                  value: members)
      end

      # Declares an array of PyMemberDef structures for a given class spec.
      def self.class_methods_declaration(class_spec)
        snake_name = class_spec.snake_case_name

        members = class_spec.method_specs.map do |func_spec|
          value = [
            ".ml_name = \"#{func_spec.name}\"",
            ".ml_meth = ( PyCFunction ) #{function_wrapper_name(func_spec)}",
            ".ml_flags = #{method_flags(func_spec)}",
            ".ml_doc = \"#{func_spec.doc.text}\""
          ]

          CSource::CDeclaration.new('PyMethodDef', nil, value: value)
        end
        members << '{NULL}'

        CSource::CDeclaration.new('PyMethodDef',
                                  "#{snake_name}_methods[]",
                                  attributes: ['static'],
                                  value: members)
      end

      # Gives a code snippet that accesses the equivalent struct from
      # within the class using the given variable name.
      def self.class_struct(class_spec, var_name: 'self')
        name = if C.equivalent_ancestor?(class_spec)
                 'super->equivalent'
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
      def self.class_struct_pointer(class_spec, var_name: 'self')
        name = if C.equivalent_ancestor?(class_spec)
                 'super->equivalent'
               else
                 "#{var_name}->equivalent"
               end

        # TODO: refactor this when moving to the new conversion convention
        if equivalent_member_declaration(class_spec).c_type.is_a?(CSource::CPointer)
          name
        else
          "&(#{name})"
        end
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
          ".tp_dealloc = ( destructor ) #{snake_name}_dealloc",
          ".tp_methods = #{snake_name}_methods",
          ".tp_members = #{snake_name}_members"
        ]

        if class_spec.functions.any?(&:constructor?)
          members << ".tp_init = #{snake_name}_init"
        end

        base_type_object = base_type_object(class_spec)
        if base_type_object.nil?
          members << ".tp_new = #{snake_name}_new"
        else
          unless runtime_class?(class_spec)
            members << ".tp_base = #{base_type_object}"
          end
        end

        Wrapture::CSource::CDeclaration.new('PyTypeObject',
                                            type_object_name(class_spec),
                                            attributes: ['static'],
                                            value: members)
      end

      # The struct used to to wrap objects of the class.
      def self.class_type_struct(class_spec)
        members = []

        # since the first portion of the PyObject structure is unknown at
        # compile time, we don't have it in the struct at all
        # see runtime_type_cast for how to recover the type struct from these
        unless runtime_class?(class_spec)
          if class_spec.child?
            parent_spec = class_spec.parent_spec
            unless parent_spec.nil?
              members << "#{type_struct_name(parent_spec)} super"
            end
          else
            members << 'PyObject_HEAD'
          end
        end

        class_spec.constants.each do |constant_spec|
          members << "#{constant_spec.type} #{constant_spec.snake_case_name};"
        end

        if C.equivalent_member?(class_spec)
          members << equivalent_member_declaration(class_spec)
        end

        CSource::CStruct.new(members: members,
                             typedef: type_struct_name(class_spec))
      end

      # The parameters used for a constructor wrapper.
      #
      # This matches the signature of the tp_init member of PyTypeObject, which
      # has type +initproc+.
      def self.constructor_params
        pyobject_ptr = CSource::CPointer.new('PyObject')

        [CSource::CDeclaration.new(pyobject_ptr, 'self_obj'),
         CSource::CDeclaration.new(pyobject_ptr, 'args'),
         CSource::CDeclaration.new(pyobject_ptr, 'kwds')]
      end

      # Creates a Python object using a variable with the given name and type.
      def self.create_python_object(type, name)
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

      # Allocates a new instance of the given class to the self variable in the
      # given source block, and performs any setup needed on it. Assumes that
      # the type variable has a pointer to the PyTypeObject structure for the
      # class.
      #
      # This is useful for constructors that need to construct the self instance
      # before calling a wrapped function with the instance.
      def self.create_self(blk, class_spec)
        self_type = "#{type_struct_name(class_spec)} *"
        blk.puts("self = ( #{self_type} ) subtype->tp_alloc( subtype, 0 );")
        blk.if('!self') do |if_blk|
          if_blk.puts('return NULL;')
        end

        class_spec.constants.each do |constant_spec|
          field_name = constant_spec.snake_case_name
          field_value = constant_spec.value
          blk.puts("self->#{field_name} = #{field_value};")
        end
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

      # Declares the local variables used in the wrapper for the given function
      # in the given block.
      def self.declare_wrapper_locals(blk, func_spec)
        class_spec = func_spec.owner

        if !func_spec.overloaded? &&
           (func_spec.constructor? || runtime_class?(class_spec))
          blk << self_declaration(class_spec)
          blk.puts(';')
        end

        # if we need an equivalent struct from a parent and this is a runtime
        # class, we'll need a super struct to reference
        if C.equivalent_ancestor?(class_spec) && runtime_class?(class_spec)
          # TODO: we may not need super if this function doesn't use the
          # equivalent struct anywhere
          type_name = type_struct_name(class_spec.parent_spec)
          blk.declare(CSource::CPointer.new(type_name), 'super')
        end

        if func_spec.params? && !func_spec.overloaded?
          blk.declare('int', 'parse_result')
        end

        error_return = func_spec[:c].error_rules.any? do |it|
          it.vals.include?(RETURN_VALUE_KEYWORD)
        end
        if !func_spec.void_return? || error_return
          return_type = func_spec.wrapped[:c].return_type
          if return_type.to_s == EQUIVALENT_STRUCT_KEYWORD
            return_type = C.equivalent_struct(func_spec.owner)
          end
          if return_type.to_s == EQUIVALENT_POINTER_KEYWORD
            return_type = C.equivalent_pointer(func_spec.owner)
          end

          return_type = 'long' if return_type == CSource::CType.new('bool')

          blk.declare(return_type, 'return_val')
        end

        # if the function is overloaded, then params are passed as args, rather
        # than being parsed in this wrapper
        unless func_spec.overloaded?
          declare_wrapper_param_locals(blk, func_spec)
        end

        blk.puts
      end

      # Declares the local variables used to pass parameters to the wrapped
      # function for the given function spec.
      def self.declare_wrapper_param_locals(blk, func_spec)
        wrapper_param_locals(func_spec).each do |decl|
          blk << decl
          blk.puts(';')
        end

        blk
      end

      # The default type allocator for classes without a base type.
      #
      # We need an allocator for our types because they are static and therefore
      # do not have a default, as described in the Python C API documentation:
      # https://docs.python.org/3/c-api/typeobj.html#c.PyTypeObject.tp_new
      def self.default_allocator(class_spec)
        name = "#{class_spec.snake_case_name}_new"
        params = allocator_params
        return_type = Wrapture::CSource::CPointer.new('PyObject')

        f = CSource::CFunction.new(name, params: params,
                                         return_type: return_type,
                                         attributes: ['static'])

        f << self_declaration(class_spec)
        f.puts(';')
        create_self(f, class_spec)
        f.puts('return ( PyObject * ) self;')

        f
      end

      # The default destructor for a class that does not have one defined.
      def self.default_destructor(class_spec)
        name = "#{class_spec.snake_case_name}_dealloc"
        params = [self_declaration(class_spec)]

        f = CSource::CFunction.new(name, params: params,
                                         attributes: ['static'])
        f.puts('Py_TYPE( self )->tp_free( ( PyObject * ) self );')

        f
      end

      # Adds definitions for functions needed for all classes in +scope+ to the
      # C source block +src+.
      def self.define_class_functions(src, scope)
        factory_classes = scope.classes.select { |it| C.factory?(it, scope) }
        factory_classes.each do |it|
          src << factory_constructor(it)
          src.puts
        end

        scope.classes.each do |class_spec|
          if base_type_object(class_spec).nil?
            src << default_allocator(class_spec)
            src.puts
          end

          # TODO: member constructors aren't implemented for Python!

          unless class_spec.functions.any?(&:destructor?)
            src << default_destructor(class_spec)
            src.puts
          end

          class_spec.functions.each do |func_spec|
            src << function_wrapper(func_spec)
            src.puts
          end
        end

        overload_groups(scope).each_value do |funcs|
          src << overload_dispatcher(funcs)
          src.puts
        end
      end

      # Generates a source file with the definition of a module for a scope.
      def self.define_module(scope)
        unless scope.definable?
          raise UndefinableSpec, "#{scope.name} is not definable"
        end

        src = CSource::CSourceFile.new("#{scope.name}.c")

        src.puts('#define PY_SSIZE_T_CLEAN')
        src.puts

        module_includes(scope).each { |it| src << it }
        src.puts

        declare_module_struct(src, scope)
        src.puts

        scope.enums.each do |enum_spec|
          src << enum_constructor(enum_spec)
          src.puts
        end

        scope.classes.each do |class_spec|
          src << class_type_struct(class_spec)
          src.declare('PyTypeObject', type_object_name(class_spec),
                      attributes: ['static'])
          src.puts
        end

        define_class_functions(src, scope)

        scope.classes.each do |class_spec|
          src << class_methods_declaration(class_spec)
          src << ";\n\n"
          src << class_members_declaration(class_spec)
          src << ";\n\n"
          src << class_type_object_declaration(class_spec)
          src << ";\n\n"
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
        create_call = "PyModule_Create( &#{scope.snake_case_name}_module )"
        init_func.puts("m = #{create_call};")
        init_func.if('!m') { |block| block.puts('goto fail;') }
        init_func.add_fail_label('fail', 'return NULL;')
        add_module_objects(init_func, scope)
        init_func.puts('return m;')

        src << init_func
      end

      # A function wrapper for a destructor.
      def self.destructor_wrapper(func_spec)
        params = [self_declaration(func_spec.owner)]

        name = function_wrapper_name(func_spec)
        f = CSource::CFunction.new(name, params: params,
                                         attributes: ['static'])
        f.puts("#{wrapped_function_call(func_spec)};")

        f.puts('Py_TYPE( self )->tp_free( ( PyObject * ) self );')

        f
      end

      # A C function which creates the given enum and adds it to the module
      # given as an argument.
      def self.enum_constructor(enum_spec)
        name = "add_#{enum_spec.snake_case_name}_enum_to_module"

        pyobject_ptr = CSource::CPointer.new('PyObject')
        params = [CSource::CDeclaration.new(pyobject_ptr, 'm')]
        f = CSource::CFunction.new(name, params: params, return_type: 'int',
                                         attributes: ['static'])

        # set up all of the local variables
        objs = %w[element_dict element_name element_value enum_name call_args
                  call_kwargs kw_name kw_value enum_mod enum_type new_enum]
        objs.each do |it|
          f.declare(pyobject_ptr, it)
        end
        f.declare('int', 'add_result')

        f.puts('element_dict = PyDict_New();')
        f.if('!element_dict') do |fail_block|
          fail_block.puts('goto dict_fail;')
        end
        f.add_fail_label('dict_fail', 'return -1;')

        next_val = 0
        enum_spec.elements.each do |it|
          element_name = Named.snake_case_name(it[:name])
          f.puts("element_name = PyUnicode_FromString( \"#{element_name}\" );")

          val = it.dig(:wrapped, :c, :value)
          val = next_val if val.nil?
          f.puts("element_value = PyLong_FromLong( #{val} );")

          set = 'PyObject_SetItem( element_dict, element_name, element_value );'
          f.puts(set)
          f.puts('Py_DECREF( element_name );')
          f.puts('Py_DECREF( element_value );')

          next_val = if val.is_a?(Integer)
                       val + 1
                     else
                       # TODO: this increment operation could be cleaner
                       next_val = "#{val} + 1"
                     end
        end

        # building the positional arguments to enum.Enum'
        enum_name = enum_spec.upper_camel_case_name
        f.puts("enum_name = PyUnicode_FromString( \"#{enum_name}\" );")
        f.puts('call_args = PyTuple_Pack( 2, enum_name, element_dict );')
        f.puts('Py_DECREF( enum_name );')
        f.puts('Py_DECREF( element_dict );')

        # building the keyword argument to enum.Enum
        f.puts('call_kwargs = PyDict_New();')
        f.puts('kw_name = PyUnicode_FromString( "module" );')
        f.puts('kw_value = PyModule_GetNameObject( m );')
        f.puts('PyObject_SetItem( call_kwargs, kw_name, kw_value );')
        f.puts('Py_DECREF( kw_name );')
        f.puts('Py_DECREF( kw_value );')

        # importing enum and getting the Enum type from it
        f.puts('enum_mod = PyImport_ImportModule( "enum" );')
        f.puts('enum_type = PyObject_GetAttrString( enum_mod, "Enum" );')
        f.puts('Py_DECREF( enum_mod );')

        # making the call to enum.Enum to create the new type
        f.puts('new_enum = PyObject_Call( enum_type, call_args, call_kwargs );')
        f.puts('Py_DECREF( enum_type );')
        f.puts('Py_DECREF( call_args );')
        f.puts('Py_DECREF( call_kwargs );')

        # adding the new type to the module
        add_params = "m, \"#{enum_name}\", new_enum"
        f.puts("add_result = PyModule_AddObjectRef( #{add_params} );")
        f.puts('Py_DECREF( new_enum );')
        f.puts('return add_result;')

        f
      end

      # The declaration of the equivalent member of this class.
      def self.equivalent_member_declaration(class_spec)
        Wrapture::CSource::CDeclaration.new(class_spec[:c], 'equivalent')
      end

      # The factory constructor for an overloaded struct.
      def self.factory_constructor(class_spec)
        name = "new_#{class_spec.name}"
        equivalent_type = C.equivalent_type(class_spec)
        params = [Wrapture::CSource::CDeclaration.new(equivalent_type,
                                                      'equivalent')]
        return_type = Wrapture::CSource::CPointer.new('PyObject')
        func = Wrapture::CSource::CFunction.new(name, params: params,
                                                      return_type: return_type)

        type_object_type = Wrapture::CSource::CPointer.new('PyTypeObject')
        func.declare(type_object_type, 'type')
        func.declare(return_type, 'obj')
        func.puts

        overload_classes = class_spec.scope.select do |it|
          C.overload?(class_spec, it)
        end
        cond = nil
        overload_classes.each do |overload|
          variable_access = if C.equivalent_type(overload).is_a?(CSource::CPointer)
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

          cond = if cond.nil?
                   func.if(check_expression)
                 else
                   cond.else_if(check_expression)
                 end

          blk = cond.if_block
          blk.puts("type = &#{type_object_name(overload)};")
          struct_type = type_struct_name(overload)
          blk.puts("#{struct_type} *new_#{struct_type};")
          struct_name = "new_#{struct_type}"
          # TODO: this probably shouldn't be using tp_alloc directly
          # see the exception action handler for a todo of the same issue
          alloc_call = "(#{struct_type} *) type->tp_alloc( type, 0 )"
          blk.puts("#{struct_name} = #{alloc_call};")

          if C.equivalent_ancestor?(overload) && runtime_class?(overload)
            parent = overload.parent_spec
            super_type = CSource::CPointer.new(type_struct_name(parent))
            super_value = runtime_type_cast(parent, struct_name)
            blk.declare(super_type, 'super', value: super_value)
          end

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

      # Performs runtime setup of the types in a module and calls PyType_Ready
      # so to register them.
      def self.finalize_module_types(blk, scope)
        scope.classes.each do |cls|
          py_type = type_object_name(cls)

          if runtime_class?(cls)
            blk.puts("#{py_type}.tp_base = #{base_type_object(cls)};")
            self_size = "sizeof( #{type_struct_name(cls)}"
            basic_size = "#{runtime_base_size(cls)} + #{self_size}"
            blk.puts("#{py_type}.tp_basicsize = #{basic_size} );")
          end

          blk.if("PyType_Ready( &#{py_type} ) < 0") do |fail_blk|
            fail_blk.puts('return NULL;')
          end
        end
      end

      # The function wrapper for a given function.
      #
      # For destructors, this function is equivalent to calling
      # +destructor_wrapper+.
      #
      # For functions that are overloaded, this function is equivalent to
      # calling +overload_wrapper+.
      #
      # For functions that have parameters and aren't overloaded, this is
      # equivalent to calling +parsing_wrapper+.
      #
      # Otherwise, this function is equivalent to calling +no_args_wrapper+.
      def self.function_wrapper(func_spec)
        if func_spec.destructor?
          destructor_wrapper(func_spec)
        elsif func_spec.overloaded?
          overload_wrapper(func_spec)
        elsif func_spec.params?
          parsing_wrapper(func_spec)
        else
          no_args_wrapper(func_spec)
        end
      end

      # The name of the function that will be defined to wrap the given
      # function.
      def self.function_wrapper_name(func_spec)
        base = func_spec.owner.snake_case_name
        method_name = if func_spec.constructor?
                        'init'
                      elsif func_spec.destructor?
                        'dealloc'
                      else
                        func_spec.name
                      end

        "#{base}_#{method_name}"
      end

      # Initializes the optional params for a function within the given block.
      def self.initialize_optional_params(blk, func_spec)
        func_spec.optional_params.each do |param_spec|
          assignment = "#{param_spec.name} = "
          assignment += if param_spec.type.name == 'const char *'
                          "\"#{param_spec.default_value}\""
                        elsif param_spec.type.name.end_with?('char')
                          "'#{param_spec.default_value}'"
                        else
                          param_spec.default_value.to_s
                        end
          blk.puts("#{assignment};")
        end
      end

      # The Python member type symbol to use for this type, suitable for use
      # with the PyMemberDef.type struct field.
      def self.member_type(type_spec)
        MEMBER_TYPE_MAP.fetch(type_spec.name, 'Py_T_OBJECT_EX')
      end

      # Gives the flags used to define the python method for the given function.
      def self.method_flags(func_spec)
        flags = if func_spec.params?
                  ['METH_VARARGS']
                else
                  ['METH_NOARGS']
                end

        flags << 'METH_STATIC' if func_spec.static?

        flags.join(' | ')
      end

      # All includes needed to define a module for the given +scope+.
      def self.module_includes(scope)
        incs = [CSource::CInclude.new('Python.h')]

        # offsetof is only needed for the member definition for constants
        if scope.classes.any? { |it| !it.constants.empty? }
          incs << CSource::CInclude.new('stddef.h', comment: 'for offsetof()')
        end

        Wrapper::C.includes(scope).each do |it|
          incs << CSource::CInclude.new(it)
        end

        incs
      end

      # A function wrapper for a function that does not have an parameters.
      #
      # TODO: there is so much constructor-specific code here that this (and
      # probably other wrappers) should probably be refactored into their own
      # wrapper methods.
      def self.no_args_wrapper(func_spec)
        name = function_wrapper_name(func_spec)
        runtime_class = runtime_class?(func_spec.owner)
        pyobject_ptr = CSource::CPointer.new('PyObject')
        unused_args = CSource::CDeclaration.new(pyobject_ptr,
                                                'Py_UNUSED( ignored )')
        params = if func_spec.constructor?
                   constructor_params
                 elsif runtime_class
                   [CSource::CDeclaration.new(pyobject_ptr, 'self_obj'),
                    unused_args]
                 else
                   [self_declaration(func_spec.owner), unused_args]
                 end

        return_type = if func_spec.constructor?
                        'int'
                      else
                        pyobject_ptr
                      end

        f = CSource::CFunction.new(name, params: params,
                                         return_type: return_type,
                                         attributes: ['static'])
        declare_wrapper_locals(f, func_spec)

        # TODO: in some cases (the exception example being one) the self pointer
        # is not actually used, but instead the super pointer is. This can be
        # collapsed to remove unused code and only do that cast if the self
        # pointer isnt' needed.
        if func_spec.constructor?
          f.puts("self = (#{type_struct_name(func_spec.owner)} *) self_obj;")
        elsif runtime_class
          self_cast = runtime_type_cast(func_spec.owner, 'self_obj')
          f.puts("self = #{self_cast};")
        end

        if C.equivalent_ancestor?(func_spec.owner) && runtime_class
          # TODO: this should also be omitted if the equivalent struct isn't
          # actually used in the function
          parent = func_spec.owner.parent_spec
          f.puts("super = #{runtime_type_cast(parent, 'self_obj')};")
        end

        f.puts("#{wrapped_function_call(func_spec)};")

        scope = func_spec.owner.scope
        wrapped_error_check(func_spec, scope).each { |it| f.puts(it) }

        f.puts(return_statement(func_spec))

        f
      end

      # A function that dispatches to the overload wrappers, based on the
      # arguments provided.
      def self.overload_dispatcher(funcs)
        # use the first function spec to determine things that are assumed to be
        # the same across all functions
        spec = funcs.first

        name = function_wrapper_name(spec)
        params = if spec.constructor?
                   type = CSource::CPointer.new('PyTypeObject')
                   [CSource::CDeclaration.new(type, 'type')]
                 else
                   [self_declaration(spec.owner)]
                 end

        pyobject_ptr = CSource::CPointer.new('PyObject')
        params << CSource::CDeclaration.new(pyobject_ptr, 'args')
        params << CSource::CDeclaration.new(pyobject_ptr, 'kwds')
        return_type = CSource::CPointer.new('PyObject')

        f = CSource::CFunction.new(name, params: params, attributes: ['static'],
                                         return_type: return_type)

        param_locals = funcs.flat_map do |it|
          wrapper_param_locals(it)
        end

        param_locals.uniq.each do |param_decl|
          f << param_decl
          f.puts(';')
        end

        f.declare('int', 'parse_result')
        if spec.constructor? || runtime_class?(spec.owner)
          f << self_declaration(spec.owner)
          f.puts(';')
        end

        create_self(f, spec.owner) if spec.constructor?

        funcs.select(&:params?).each do |func_spec|
          # TODO: there may be a more efficient way to do this than repeatedly
          # initialize the optionals for every overload
          initialize_optional_params(f, func_spec)
          f.puts("parse_result = #{parse_tuple_call(func_spec)};")
          f.if('parse_result') do |if_blk|
            if_blk.puts("return #{overload_wrapper_call(func_spec)};")
          end
        end

        unless funcs.all?(&:params?)
          f.puts('// TODO need to handle no arg case cleaner')
          f.puts('// preferably, check if args are empty up front')
          f.puts('// for now, it is the fallback case')
          no_args = funcs.find { |func_spec| !func_spec.params? }
          f.puts("return #{overload_wrapper_call(no_args)};")
        end

        f.puts('// TODO need to throw an error if no overload matched')
        f.puts('// PyArg_ParseTuple will raise an exception on failure:')
        f.puts('// we probably need to replace this with our own')

        f
      end

      # The function overload groups for a +scope+, provided as a +Hash+ that
      # maps the function name to an +Array+ of +FunctionSpec+ instances that
      # are overloaded under that name.
      def self.overload_groups(scope)
        overload_groups = {}
        scope.classes.each do |class_spec|
          class_spec.functions.each do |func_spec|
            if func_spec.overloaded?
              if overload_groups.include?(func_spec.name)
                overload_groups[func_spec.name] << func_spec
              else
                overload_groups[func_spec.name] = [func_spec]
              end
            end
          end
        end

        overload_groups
      end

      # A function wrapper for a function that is overloaded by others.
      #
      # Overloaded function wrappers do not do any Python argument parsing, but
      # instead take the C arguments directly.
      def self.overload_wrapper(func_spec)
        params = [self_declaration(func_spec.owner)]
        params += wrapper_param_locals(func_spec)
        return_type = CSource::CPointer.new('PyObject')

        f = CSource::CFunction.new(overload_wrapper_name(func_spec),
                                   return_type: return_type,
                                   params: params, attributes: ['static'])

        declare_wrapper_locals(f, func_spec)
        f.puts("#{wrapped_function_call(func_spec)};")
        f.puts(return_statement(func_spec))

        f
      end

      # A call to the overload wrapper defined for +func_spec+.
      def self.overload_wrapper_call(func_spec)
        name = overload_wrapper_name(func_spec)
        args = wrapper_param_locals(func_spec).map(&:name)
        args.prepend('self')
        "#{name}( #{args.join(', ')} )"
      end

      # The name of the function that will be defined to wrap the given
      # function.
      def self.overload_wrapper_name(func_spec)
        base = function_wrapper_name(func_spec)

        types = if func_spec.params?
                  func_spec.params.map { |p| p.type.base }.join('_')
                else
                  'no_args'
                end

        "#{base}_#{types}"
      end

      # The format string for PyArg_ParseTuple for the given function parameter.
      def self.param_format(func_spec, param_spec)
        key = func_spec.resolve_type(param_spec.type).to_s
        TYPE_FORMAT_UNIT_MAP.fetch(key, 'O')
      end

      # True if the provided wrapped param spec can be cast to when used in this
      # function.
      def self.param_uses_equivalent?(func_spec, wrapped_param)
        param = func_spec.params.find { |p| p.name == wrapped_param.value }

        !param.nil? &&
          !wrapped_param.c_type.nil? &&
          func_spec.owner.type?(param.type)
      end

      # The expression containing the call to the PyArg_ParseTuple.
      def self.parse_tuple_call(func_spec)
        format_str = "\"#{arg_parse_format(func_spec)}\""
        arg_vars = wrapper_param_locals(func_spec).map do |decl|
          "&#{decl.name}"
        end
        "PyArg_ParseTuple( args, #{format_str}, #{arg_vars.join(', ')} )"
      end

      # A function wrapper for a function that parses its parameters from Python
      # arguments.
      def self.parsing_wrapper(func_spec)
        name = function_wrapper_name(func_spec)
        pyobject_ptr = CSource::CPointer.new('PyObject')

        params = if func_spec.constructor?
                   constructor_params
                 else
                   [self_declaration(func_spec.owner),
                    CSource::CDeclaration.new(pyobject_ptr, 'args'),
                    CSource::CDeclaration.new(pyobject_ptr, 'kwds')]
                 end

        f = CSource::CFunction.new(name, params: params,
                                         return_type: pyobject_ptr,
                                         attributes: ['static'])

        declare_wrapper_locals(f, func_spec)
        initialize_optional_params(f, func_spec)

        f.puts("parse_result = #{parse_tuple_call(func_spec)};")
        f.if('!parse_result') do |if_blk|
          if_blk.puts('return NULL;')
        end

        # TODO: in some cases (the exception example being one) the self pointer
        # is not actually used, but instead the super pointer is. This can be
        # collapsed to remove unused code and only do that cast if the self
        # pointer isnt' needed.
        runtime_class = runtime_class?(func_spec.owner)
        if func_spec.constructor?
          f.puts("self = (#{type_struct_name(func_spec.owner)} *) self_obj;")
        elsif runtime_class
          self_cast = runtime_type_cast(func_spec.owner, 'self_obj')
          f.puts("self = #{self_cast};")
        end

        if C.equivalent_ancestor?(func_spec.owner) && runtime_class
          # TODO: this should also be omitted if the equivalent struct isn't
          # actually used in the function
          parent = func_spec.owner.parent_spec
          f.puts("super = #{runtime_type_cast(parent, 'self_obj')};")
        end

        f.puts("#{wrapped_function_call(func_spec)};")

        scope = func_spec.owner.scope
        wrapped_error_check(func_spec, scope).each { |it| f.puts(it) }

        f.puts(return_statement(func_spec))

        f
      end

      # The expression to use for a value in an ActionSpec.
      def self.resolve_action_value(func_spec, val)
        case val
        when EQUIVALENT_STRUCT_KEYWORD
          class_struct(func_spec.owner)
        when EQUIVALENT_POINTER_KEYWORD
          class_struct_pointer(func_spec.owner)
        when RETURN_VALUE_KEYWORD
          'return_val'
        else
          val
        end
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
          cast_equivalent(param_class, used_param.name, param.c_type)
        else
          param.value
        end
      end

      # The return statement used in this function's definition.
      def self.return_statement(func_spec)
        if func_spec.constructor?
          'return 0;'
        elsif func_spec.return_type.self_reference?
          'return self;'
        elsif func_spec.void_return?
          'Py_RETURN_NONE;'
        elsif func_spec.return_overloaded?
          overload = "new_#{func_spec.return_type.name.chomp('*').strip}"
          "return #{overload}( return_val );"
        else
          return_value = create_python_object(func_spec.return_type,
                                              'return_val')
          if return_value.empty?
            'return;'
          else
            "return #{return_value};"
          end
        end
      end

      # An expression with the size of the base type for +class_spec+.
      def self.runtime_base_size(class_spec)
        "#{base_type_object(class_spec)}->tp_basicsize"
      end

      # True if some aspects of the class need to be defined at runtime.
      #
      # Exception classes are one example of this case, as the Exception class
      # and its associated type information are not available until runtime.
      def self.runtime_class?(class_spec)
        class_spec.exception?
      end

      # A cast of a runtime type to the class type struct.
      def self.runtime_type_cast(class_spec, var_name)
        type_struct_name = type_struct_name(class_spec)
        type_object = base_type_object(class_spec)
        real_self = "((intptr_t) #{var_name}) + #{type_object}->tp_basicsize"
        "( #{type_struct_name} * )( #{real_self} )"
      end

      # A declaration of a pointer to an instance of +class_spec+ named self.
      def self.self_declaration(class_spec)
        pointer_type = CSource::CPointer.new(type_struct_name(class_spec))
        CSource::CDeclaration.new(pointer_type, 'self')
      end

      # Gives the name of the type object instance for a given class.
      def self.type_object_name(class_spec)
        "#{class_spec.snake_case_name}_type_object"
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
        set = PythonSource::PythonSourceSet.new(scope.snake_case_name)

        set.add_module_source(define_module(scope))

        scope.libraries.each do |lib|
          set.add_link(lib)
        end

        set
      end

      # An +Array+ of C source to check for errors after the wrapped call in
      # a function.
      def self.wrapped_error_check(func_spec, scope)
        return [] unless func_spec[:c].error_check?

        action = func_spec[:c].error_action
        exception_class = scope.type(action.type)
        type_object = "(PyObject *) &#{type_object_name(exception_class)}"

        checks = func_spec[:c].error_rules.map do |rule|
          resolved_vals = rule.vals.map do |it|
            resolve_action_value(func_spec, it)
          end

          CSource::CExpression.new(resolved_vals, rule.operator)
        end

        check_expr = CSource::CExpression.new(checks, :or)
        check_blk = CSource::CIf.new(check_expr) do |blk|
          # TODO: this all assumes that this constructor will work on the type,
          # which probably shouldn't always be the case. Instead, a way to
          # create they object from the equivalent struct should probable be
          # added and invoked here instead.
          call_type = "PyObject_CallNoArgs(#{type_object})"
          blk.puts("PyObject *exception_obj = #{call_type};")

          equiv_class = if C.equivalent_ancestor?(exception_class)
                          exception_class.parent_spec
                        else
                          exception_class
                        end
          cast = runtime_type_cast(equiv_class, 'exception_obj')
          blk.puts("#{type_struct_name(equiv_class)} *subtype = #{cast};")

          value_variable = resolve_action_value(func_spec, action.value)
          blk.puts("subtype->equivalent = #{value_variable};")
          blk.puts("PyErr_SetObject(#{type_object}, exception_obj );")
          # TODO: need to detect whether a different error return is needed,
          # for example -1
          blk.puts('return NULL;')
        end

        [check_blk]
      end

      # The expression containing the call to the underlying wrapped function.
      def self.wrapped_function_call(func_spec)
        resolved_params = func_spec[:c].params.map do |param|
          resolve_wrapped_param(func_spec, param)
        end

        call = "#{func_spec[:c].name}( #{resolved_params.join(', ')} )"

        if func_spec.constructor?
          "#{class_struct_pointer(func_spec.owner)} = #{call}"
        elsif func_spec[:c].error_check? || !func_spec.void_return?
          "return_val = #{call}"
        else
          call
        end
      end

      # Declares the local variables used to pass parameters to the wrapped
      # function for the given function spec.
      def self.wrapper_param_locals(func_spec)
        func_spec.params.map do |param_spec|
          param_type = func_spec.resolve_type(param_spec.type)

          if func_spec.owner.scope.type?(param_type)
            param_type = CSource::CPointer.new(type_struct_name(param_type))
          end

          CSource::CDeclaration.new(param_type, param_spec.name)
        end
      end
    end
  end
end
