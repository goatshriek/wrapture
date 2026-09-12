# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025-2026 Joel E. Anderson
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

      # Adds code to the source file +src+ to add the class and enum type
      # objects to the module for +context+.
      def self.add_module_objects(src, context)
        context.classes.each do |it|
          class_spec = it.root
          object_name = type_object_name(class_spec)
          fail_label = "fail_add_#{object_name}"
          add_class_object(src, class_spec, fail_label)
          src.add_fail_label(fail_label, "Py_DECREF( &#{object_name} );")
        end

        context.enums.each do |it|
          enum_spec = it.root
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
      def self.arg_parse_format(required_args, optional_args = [])
        required_formats = required_args.map do |key|
          TYPE_FORMAT_UNIT_MAP.fetch(key, 'O')
        end

        optional_formats = optional_args.map do |key|
          TYPE_FORMAT_UNIT_MAP.fetch(key, 'O')
        end

        if optional_formats.empty?
          required_formats.join
        else
          "#{required_formats.join}|#{optional_formats.join}"
        end
      end

      # Get the name of the type object for base of the class at the root of
      # +context+.
      def self.base_type_object(context)
        class_spec = context.root
        if class_spec.child?
          parent_spec = context.resolve_name(context.parent)
          return "(&#{type_object_name(parent_spec)})" if parent_spec
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

      # Declares an array of PyMemberDef structures for the class at the root of
      # +context+.
      def self.class_methods_declaration(context)
        snake_name = context.root.snake_case_name

        members = context.methods.map do |it|
          func_spec = it.root
          value = [
            ".ml_name = \"#{func_spec.snake_case_name}\"",
            ".ml_meth = ( PyCFunction ) #{function_wrapper_name(it)}",
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
      # within the class at the root of +context+ using the given variable name.
      def self.class_struct(context, var_name: 'self')
        class_spec = context.root
        name = if C.equivalent_ancestor?(context)
                 if runtime_class?(class_spec)
                   'super->equivalent'
                 else
                   "#{var_name}->super.equivalent"
                 end
               else
                 "#{var_name}->equivalent"
               end

        # TODO: refactor this when moving to the new conversion convention
        if equivalent_member_declaration(class_spec).c_type.is_a?(CSource::CPointer)
          "*(#{name})"
        else
          name
        end
      end

      # Gives a code snippet that accesses the equivalent struct pointer from
      # within the class at the root of +context+ using the given variable name.
      def self.class_struct_pointer(context, var_name: 'self')
        class_spec = context.root
        name = if C.equivalent_ancestor?(context)
                 if runtime_class?(class_spec)
                   'super->equivalent'
                 else
                   "#{var_name}->super.equivalent"
                 end
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

      # Defines a PyTypeObject struct for the class at the root of +context+.
      def self.class_type_object_declaration(context)
        class_spec = context.root
        snake_name = class_spec.snake_case_name
        mod = Python.module_name(context.parent.root)
        type_name = "#{mod}.#{class_spec.upper_camel_case_name}"
        flags = 'Py_TPFLAGS_DEFAULT'
        children_in_context = context.flatten.any? do |it|
          it.child?(class_spec)
        end
        flags += ' | Py_TPFLAGS_BASETYPE' if children_in_context

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

        if context.constructors?
          members << ".tp_init = #{snake_name}_init"
        elsif member_constructor?(context)
          members << ".tp_init = #{member_constructor_name(class_spec)}"
        end

        base_type_object = base_type_object(context)
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

      # The struct used to to wrap objects of the class at the root of
      # +context+.
      def self.class_type_struct(context)
        class_spec = context.root
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

        if C.equivalent_member?(context)
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

      # True if the constructors for the class at the root of +context+ are
      # overloaded, and need to be dynamically dispatched.
      def self.constructors_overloaded?(context)
        constructor_count = context.constructors.length
        constructor_count.increment if member_constructor?(context)
        constructor_count > 1
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

      # Declares the module definition struct (PyModuleDef) for +module_name+
      # in source file +src+.
      def self.declare_module_struct(src, module_name)
        module_struct = CSource::CStruct.new(name: 'PyModuleDef')
        module_fields = ['.m_base = PyModuleDef_HEAD_INIT',
                         ".m_name = \"#{module_name}\"",
                         '.m_doc = NULL',
                         '.m_size = -1']
        src.declare(module_struct, "#{module_name}_module",
                    attributes: ['static'],
                    value: module_fields)
      end

      # Adds declarations to +blk+ for the local variables used in the wrapper
      # for the the function at the root of +context+.
      def self.declare_wrapper_locals(blk, context)
        func_spec = context.root
        class_spec = context.parent.root

        if !func_spec.overloaded? &&
           (func_spec.constructor? || runtime_class?(class_spec))
          blk.statement(self_declaration(class_spec))
        end

        # if we need an equivalent struct from a parent and this is a runtime
        # class, we'll need a super struct to reference
        if C.equivalent_ancestor?(context.parent) && runtime_class?(class_spec)
          # TODO: we may not need super if this function doesn't use the
          # equivalent struct anywhere
          type_name = type_struct_name(context.parent.parent.root)
          blk.declare(CSource::CPointer.new(type_name), 'super')
        end

        if func_spec.params? && !func_spec.overloaded?
          blk.declare('int', 'parse_result')
        end

        error_return = func_spec[:c].error_rules.any? do |it|
          it.vals.include?(RETURN_VALUE_KEYWORD)
        end
        if !func_spec.void_return? || error_return
          blk.declare(source_return_type(context), 'return_val')
        end

        # if the function is overloaded, then params are passed as args, rather
        # than being parsed in this wrapper
        declare_wrapper_param_locals(blk, context) unless func_spec.overloaded?

        blk.puts
      end

      # Declares the local variables used to pass parameters to the wrapped
      # function for the function at the root of +context+.
      def self.declare_wrapper_param_locals(blk, context)
        wrapper_param_locals(context).each do |decl|
          blk.statement(decl)
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

        f.statement(self_declaration(class_spec))
        create_self(f, class_spec)
        f.return('( PyObject * ) self')
      end

      # The default destructor for a class that does not have one defined.
      def self.default_destructor(class_spec)
        name = "#{class_spec.snake_case_name}_dealloc"
        params = [self_declaration(class_spec)]

        f = CSource::CFunction.new(name, params: params,
                                         attributes: ['static'])
        f.statement('Py_TYPE( self )->tp_free( ( PyObject * ) self )')
      end

      # Adds definitions for functions needed for all classes in +context+ to
      # the C source block +src+.
      def self.define_class_functions(src, context)
        factory_classes = context.classes.select { |it| C.factory?(it) }
        factory_classes.each do |it|
          src << factory_constructor(it)
          src.puts
        end

        context.classes.each do |it|
          class_spec = it.root
          if base_type_object(it).nil?
            src << default_allocator(class_spec)
            src.puts
          end

          if member_constructor?(it)
            src << member_constructor(it)
            src.puts
          end

          unless it.functions.any? { |it| it.root.destructor? }
            src << default_destructor(class_spec)
            src.puts
          end

          it.functions.each do |it|
            src << function_wrapper(it)
            src.puts
          end
        end

        overload_groups(context).each_value do |funcs|
          src << overload_dispatcher(funcs)
          src.puts
        end
      end

      # Generates a source file with the definition of a module for +context+.
      def self.define_module(context)
        module_name = Python.module_name(context.root)
        src = CSource::CSourceFile.new("#{module_name}.c")

        src.puts('#define PY_SSIZE_T_CLEAN')
        src.puts

        src.concat(module_includes(context))
        src.puts

        declare_module_struct(src, module_name)
        src.puts

        context.enums.each do |it|
          src << enum_constructor(it.root)
          src.puts
        end

        context.classes.each do |it|
          class_spec = it.root
          src << class_type_struct(it)
          src.declare('PyTypeObject', type_object_name(class_spec),
                      attributes: ['static'])
          src.puts
        end

        define_class_functions(src, context)

        context.classes.each do |it|
          class_spec = it.root
          src.statement(class_methods_declaration(it))
          src.statement(class_members_declaration(class_spec))
          src.statement(class_type_object_declaration(it))
        end

        define_module_init(src, context)
      end

      # Add the definition of the module init function for +context+ to source
      # file +src+.
      def self.define_module_init(src, context)
        module_name = Python.module_name(context.root)
        return_type = CSource::CType.new('PyMODINIT_FUNC')
        init_func = CSource::CFunction.new("PyInit_#{module_name}",
                                           return_type: return_type)
        init_func.puts('PyObject *m;')
        finalize_module_types(init_func, context)
        create_call = "PyModule_Create( &#{module_name}_module )"
        init_func.puts("m = #{create_call};")
        init_func.if('!m') { |block| block.puts('goto fail;') }
        init_func.add_fail_label('fail', 'return NULL;')
        add_module_objects(init_func, context)
        init_func.puts('return m;')

        src << init_func
      end

      # A function wrapper for the destructor at the root of +context+.
      def self.destructor_wrapper(context)
        params = [self_declaration(context.parent.root)]

        name = function_wrapper_name(context)
        f = CSource::CFunction.new(name, params: params,
                                         attributes: ['static'])
        f.statement(wrapped_function_call(context))
        f.statement('Py_TYPE( self )->tp_free( ( PyObject * ) self )')
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

          val = it.dig(:source, :c, :value)
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
        f.return('add_result')
      end

      # The declaration of the equivalent member of this class.
      def self.equivalent_member_declaration(class_spec)
        Wrapture::CSource::CDeclaration.new(class_spec[:c], 'equivalent')
      end

      # The factory constructor for the class at the root of +context+.
      def self.factory_constructor(context)
        class_spec = context.root
        name = "new_#{class_spec.upper_camel_case_name}"
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

        overload_classes = C.overloads(context)
        cond = nil
        overload_classes.each do |it|
          overloaded = it.root
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

          if C.equivalent_ancestor?(it) && runtime_class?(overload)
            parent = it.parent.parent
            super_type = CSource::CPointer.new(type_struct_name(parent.root))
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

      # Adds code to +blk+ which performs runtime setup of the types in the
      # module +context+ and calls PyType_Ready to register them.
      def self.finalize_module_types(blk, context)
        context.classes.each do |it|
          cls = it.root
          py_type = type_object_name(cls)

          if runtime_class?(cls)
            blk.puts("#{py_type}.tp_base = #{base_type_object(it)};")
            self_size = "sizeof( #{type_struct_name(cls)}"
            basic_size = "#{runtime_base_size(it)} + #{self_size}"
            blk.puts("#{py_type}.tp_basicsize = #{basic_size} );")
          end

          blk.if("PyType_Ready( &#{py_type} ) < 0") do |fail_blk|
            fail_blk.puts('return NULL;')
          end
        end
      end

      # The format string to use for +func_spec+.
      def self.function_arg_parse_format(func_spec)
        required_args = func_spec.required_params.map do |param_spec|
          func_spec.resolve_type(param_spec.type).to_s
        end
        optional_args = func_spec.optional_params.map do |param_spec|
          func_spec.resolve_type(param_spec.type).to_s
        end
        arg_parse_format(required_args, optional_args)
      end

      # The function wrapper for the funtion at the root of +context+.
      #
      # For destructors, this function calls +destructor_wrapper+.
      #
      # For functions that are overloaded, this function calls
      # +overload_wrapper+.
      #
      # For functions that have parameters and aren't overloaded, this function
      # calls +parsing_wrapper+.
      #
      # Otherwise, this function is equivalent to calling +no_args_wrapper+.
      def self.function_wrapper(context)
        func_spec = context.root
        if func_spec.destructor?
          destructor_wrapper(context)
        elsif func_spec.overloaded?
          overload_wrapper(context)
        elsif func_spec.params?
          parsing_wrapper(context)
        else
          no_args_wrapper(context)
        end
      end

      # The name of the C function that will be defined to wrap the function at
      # the root of +context+.
      def self.function_wrapper_name(context)
        # TODO: what if the function is not in a class?
        base = context.parent.root.snake_case_name
        func_spec = context.root
        method_name = if func_spec.constructor?
                        'init'
                      elsif func_spec.destructor?
                        'dealloc'
                      else
                        func_spec.snake_case_name
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
          blk.statement(assignment)
        end
      end

      # A member constructor uses the members of the struct wrapped by the
      # class at the root of +context+ to fill in the struct.
      def self.member_constructor(context)
        if constructors_overloaded?(context)
          member_constructor_overload_wrapper(class_spec)
        else
          member_constructor_parsing_wrapper(class_spec)
        end
      end

      # True if the given class at the root of +context+ will generate a member
      # constructor.
      def self.member_constructor?(context)
        C.wrapped_members?(context.root)
      end

      # The format string to use for the arguments for the member constructor
      # for +class_spec+.
      def self.member_constructor_arg_parse_format(class_spec)
        required_args = []
        optional_args = []

        class_spec[:c].members.each do |member|
          if member.value.nil?
            required_args << member.c_type.to_s
          else
            optional_args << member.c_type.to_s
          end
        end

        arg_parse_format(required_args, optional_args)
      end

      # The name of the member constructor for +class_spec+.
      def self.member_constructor_name(class_spec)
        "#{class_spec.snake_case_name}_member_constructor"
      end

      # A call to the member constructor for +class_spec+.
      def self.member_constructor_call(class_spec)
        name = member_constructor_name(class_spec)
        args = class_spec[:c].members.map(&:name)
        "#{name}( self, #{args.join(', ')} )"
      end

      # A member constructor for +class_spec+ that performs the parsing of
      # arguments as supplied by Python.
      def self.member_constructor_overload_wrapper(class_spec)
        name = member_constructor_name(class_spec)
        params = [self_declaration(class_spec)] + class_spec[:c].members
        return_type = Wrapture::CSource::CPointer.new('PyObject')

        f = CSource::CFunction.new(name, params: params,
                                         return_type: return_type,
                                         attributes: ['static'])

        class_struct = class_struct(class_spec)
        class_spec[:c].members.each do |member|
          f.statement("#{class_struct}.#{member.name} = #{member.name}")
        end

        f.puts
        f.return('self')

        f
      end

      # A call to PyArg_ParseTuple for the member constructor of +class_spec+.
      def self.member_constructor_parse_tuple_call(class_spec)
        format_str = member_constructor_arg_parse_format(class_spec)

        arg_vars = class_spec[:c].members.map do |member|
          "&#{member.name}"
        end

        "PyArg_ParseTuple( args, \"#{format_str}\", #{arg_vars.join(', ')})"
      end

      # A member constructor for the class at the root of +context+ that
      # performs the parsing of arguments as supplied by Python.
      def self.member_constructor_parsing_wrapper(context)
        class_spec = context.root
        name = member_constructor_name(class_spec)
        f = CSource::CFunction.new(name, params: constructor_params,
                                         return_type: 'int',
                                         attributes: ['static'])

        class_spec[:c].members.each do |member|
          f.statement(member)
        end
        f.declare('int', 'parse_result')
        f.statement(self_declaration(class_spec))

        # TODO: ideally we would instead pass in the address of the equivalent
        # struct members instead of creating locals and copying them over
        # for now we're doing things this way to reuse the parse tuple call
        tuple_call = member_constructor_parse_tuple_call(class_spec)
        f.statement("parse_result = #{tuple_call}")
        f.if('!parse_result') do |if_blk|
          if_blk.return('-1')
        end

        runtime_class = runtime_class?(class_spec)
        if runtime_class
          self_cast = runtime_type_cast(context, 'self_obj')
          f.puts("self = #{self_cast};")
        else
          f.puts("self = (#{type_struct_name(class_spec)} *) self_obj;")
        end

        class_struct = class_struct(class_spec)
        class_spec[:c].members.each do |member|
          f.statement("#{class_struct}.#{member.name} = #{member.name}")
        end

        f.return('0')

        f
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

      # All includes needed to define a module for +context+.
      def self.module_includes(context)
        incs = Wrapper::C.includes(context).map do |it|
          CSource::CInclude.new(it)
        end

        # offsetof is only needed for the member definition for constants
        classes = context.flatten.select { |it| it.root.is_a?(ClassSpec) }
        unless classes.all? { |it| it.constants.empty? }
          incs << CSource::CInclude.new('stddef.h', comment: 'for offsetof()')
        end

        Wrapper::C.includes(context).each do |it|
          incs << CSource::CInclude.new(it)
        end

        incs << CSource::CInclude.new('Python.h')
      end

      # A wrapper for the function at the root of +context+ that does not have
      # an parameters.
      #
      # TODO: there is so much constructor-specific code here that this (and
      # probably other wrappers) should probably be refactored into their own
      # wrapper methods.
      def self.no_args_wrapper(context)
        func_spec = context.root
        class_spec = context.parent.root
        name = function_wrapper_name(context)
        runtime_class = runtime_class?(class_spec)
        pyobject_ptr = CSource::CPointer.new('PyObject')
        unused_args = CSource::CDeclaration.new(pyobject_ptr,
                                                'Py_UNUSED( ignored )')
        params = if func_spec.constructor?
                   constructor_params
                 elsif runtime_class
                   [CSource::CDeclaration.new(pyobject_ptr, 'self_obj'),
                    unused_args]
                 else
                   [self_declaration(class_spec), unused_args]
                 end

        return_type = wrapper_return_type(func_spec)

        f = CSource::CFunction.new(name, params: params,
                                         return_type: return_type,
                                         attributes: ['static'])
        declare_wrapper_locals(f, context)

        # TODO: in some cases (the exception example being one) the self pointer
        # is not actually used, but instead the super pointer is. This can be
        # collapsed to remove unused code and only do that cast if the self
        # pointer isnt' needed.
        if func_spec.constructor?
          f.puts("self = (#{type_struct_name(class_spec)} *) self_obj;")
        elsif runtime_class
          self_cast = runtime_type_cast(class_spec, 'self_obj')
          f.puts("self = #{self_cast};")
        end

        if C.equivalent_ancestor?(context.parent) && runtime_class
          # TODO: this should also be omitted if the equivalent struct isn't
          # actually used in the function
          parent = context.parent.parent.root
          f.puts("super = #{runtime_type_cast(parent, 'self_obj')};")
        end

        f.puts("#{wrapped_function_call(context)};")

        wrapped_error_check(context).each { |it| f.puts(it) }

        f.puts(return_statement(func_spec))

        f
      end

      # A function that dispatches to the overload wrappers, based on the
      # arguments provided.
      def self.overload_dispatcher(func_contexts)
        # use the first function spec to determine things that are assumed to be
        # the same across all functions
        first_context = func_contexts.first
        first_spec = first_context.root
        class_spec = first_context.parent.root

        name = function_wrapper_name(first_context)
        params = if first_spec.constructor?
                   constructor_params
                 else
                   pyobject_ptr = CSource::CPointer.new('PyObject')
                   [self_declaration(class_spec),
                    CSource::CDeclaration.new(pyobject_ptr, 'args'),
                    CSource::CDeclaration.new(pyobject_ptr, 'kwds')]
                 end

        return_type = if first_spec.constructor?
                        'int'
                      else
                        CSource::CPointer.new('PyObject')
                      end

        f = CSource::CFunction.new(name, params: params, attributes: ['static'],
                                         return_type: return_type)

        param_locals = func_contexts.flat_map do |it|
          wrapper_param_locals(it)
        end

        param_locals.uniq.each do |param_decl|
          f.statement(param_decl)
        end

        f.declare('int', 'parse_result')
        if first_spec.constructor? || runtime_class?(class_spec)
          f.statement(self_declaration(class_spec))
        end

        param_functions = func_contexts.select { |it| it.root.params? }
        param_functions.each do |it|
          # TODO: there may be a more efficient way to do this than repeatedly
          # initialize the optionals for every overload
          func_spec = it.root
          initialize_optional_params(f, func_spec)
          f.puts("parse_result = #{parse_tuple_call(it)};")
          f.if('parse_result') do |if_blk|
            if_blk.puts("return #{overload_wrapper_call(it)};")
          end
        end

        # the member constructor must be handled separately since there isn't a
        # FunctionSpec for it
        if member_constructor?(first_context.parent)
          parse_call = member_constructor_parse_tuple_call(class_spec)
          f.puts("parse_result = #{parse_call};")
          f.if('parse_result') do |if_blk|
            if_blk.puts("return #{member_constructor_call(class_spec)};")
          end
        end

        no_args = func_contexts.find { |it| !it.root.params? }
        unless no_args.nil?
          # TODO: need to handle no arg case cleaner
          # preferably, check if args are empty up front
          # for now, it is the fallback case
          f.puts("return #{overload_wrapper_call(no_args)};")
        end

        # TODO: need to throw an error if no overload matched
        # PyArg_ParseTuple will raise an exception on failure:
        # we probably need to replace this with our own

        f
      end

      # The function overload groups for a +context+, provided as a +Hash+ that
      # maps the function name to an +Array+ of +FunctionSpec+ instances that
      # are overloaded under that name.
      def self.overload_groups(context)
        # TODO: what if the same function name is overloaded in multiple classes?
        # currently this results in conflicts
        overload_groups = {}
        context.classes.each do |it|
          wrapped_members = C.wrapped_members?(it.root)

          it.functions.each do |func_context|
            func_spec = func_context.root
            func_name = func_spec.snake_case_name
            overloaded_constructor = func_spec.constructor? && wrapped_members
            if func_spec.overloaded? || overloaded_constructor
              if overload_groups.include?(func_name)
                overload_groups[func_name] << func_context
              else
                overload_groups[func_name] = [func_context]
              end
            end
          end
        end

        overload_groups
      end

      # A function wrapper for the function at the root of +context+ which
      # is overloaded by others.
      #
      # Overloaded function wrappers do not do any Python argument parsing, but
      # instead take the C arguments directly.
      def self.overload_wrapper(context)
        func_spec = context.root
        params = [self_declaration(context.parent.root)]
        params += wrapper_param_locals(context)
        return_type = wrapper_return_type(func_spec)

        f = CSource::CFunction.new(overload_wrapper_name(context),
                                   return_type: return_type,
                                   params: params, attributes: ['static'])

        declare_wrapper_locals(f, context)
        f.puts("#{wrapped_function_call(context)};")
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

      # The name of the function that will be defined to wrap the function
      # at the root of +context+.
      def self.overload_wrapper_name(context)
        base = function_wrapper_name(context)

        func_spec = context.root
        types = if func_spec.params?
                  func_spec.params.map { |p| p.type.base }.join('_')
                else
                  'no_args'
                end

        "#{base}_#{types}"
      end

      # True if the provided +wrapped_param+ can be cast to when used in the
      # function at the root of +context+.
      def self.param_uses_equivalent?(context, wrapped_param)
        param = context.root.params.find { |p| p.name == wrapped_param.value }

        !param.nil? &&
          !wrapped_param.c_type.nil? &&
          !context.resolve_name(param.type.name_words).nil?
      end

      # The expression containing the call to PyArg_ParseTuple to parse the
      # arguments for the function at the root of +context+.
      def self.parse_tuple_call(context)
        format_str = function_arg_parse_format(context.root)
        arg_vars = wrapper_param_locals(context).map do |decl|
          "&#{decl.name}"
        end
        "PyArg_ParseTuple( args, \"#{format_str}\", #{arg_vars.join(', ')} )"
      end

      # A C wrapper for the function at the root of +context+ which parses its
      # parameters from Python arguments.
      def self.parsing_wrapper(context)
        func_spec = context.root
        class_spec = context.parent.root
        name = function_wrapper_name(context)
        pyobject_ptr = CSource::CPointer.new('PyObject')

        params = if func_spec.constructor?
                   constructor_params
                 else
                   [self_declaration(class_spec),
                    CSource::CDeclaration.new(pyobject_ptr, 'args'),
                    CSource::CDeclaration.new(pyobject_ptr, 'kwds')]
                 end

        return_type = wrapper_return_type(func_spec)

        f = CSource::CFunction.new(name, params: params,
                                         return_type: return_type,
                                         attributes: ['static'])

        declare_wrapper_locals(f, context)
        initialize_optional_params(f, func_spec)

        f.puts("parse_result = #{parse_tuple_call(context)};")
        f.if('!parse_result') do |if_blk|
          if func_spec.constructor?
            if_blk.return('-1')
          else
            if_blk.return('NULL')
          end
        end

        # TODO: in some cases (the exception example being one) the self pointer
        # is not actually used, but instead the super pointer is. This can be
        # collapsed to remove unused code and only do that cast if the self
        # pointer isnt' needed.
        runtime_class = runtime_class?(class_spec)
        if runtime_class
          self_cast = runtime_type_cast(class_spec, 'self_obj')
          f.puts("self = #{self_cast};")
        elsif func_spec.constructor?
          f.puts("self = (#{type_struct_name(class_spec)} *) self_obj;")
        end

        if C.equivalent_ancestor?(context.parent) && runtime_class
          # TODO: this should also be omitted if the equivalent struct isn't
          # actually used in the function
          parent = context.parent.parent.root
          f.puts("super = #{runtime_type_cast(parent, 'self_obj')};")
        end

        f.puts("#{wrapped_function_call(context)};")

        wrapped_error_check(context).each { |it| f.puts(it) }

        f.puts(return_statement(func_spec))

        f
      end

      # The expression to use for a value in an ActionSpec.
      def self.resolve_action_value(class_spec, val)
        case val
        when EQUIVALENT_STRUCT_KEYWORD
          class_struct(class_spec)
        when EQUIVALENT_POINTER_KEYWORD
          class_struct_pointer(class_spec)
        when RETURN_VALUE_KEYWORD
          'return_val'
        else
          val
        end
      end

      # Gives an expression for using a given parameter +param+ in the function
      # at the root of +context+. Equivalent structs and pointers are resolved,
      # as well as casts between types if they are known within the context of
      # this function.
      def self.resolve_wrapped_param(context, param)
        func_spec = context.root
        used_param = func_spec.params.find { |p| p.name == param.value }

        if param.value == EQUIVALENT_STRUCT_KEYWORD
          class_struct(context.parent)
        elsif param.value == EQUIVALENT_POINTER_KEYWORD
          class_struct_pointer(context.parent)
        elsif param.value == '...'
          'variadic_args'
        elsif param_uses_equivalent?(context, param)
          param_class = context.resolve_name(used_param.type.name_words).root
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

      # An expression with the size of the base type for the class at the base
      # of +context+.
      def self.runtime_base_size(context)
        "#{base_type_object(context)}->tp_basicsize"
      end

      # True if some aspects of the class need to be defined at runtime.
      #
      # Exception classes are one example of this case, as the Exception class
      # and its associated type information are not available until runtime.
      def self.runtime_class?(class_spec)
        class_spec.exception?
      end

      # A cast of a runtime type of the class at the root of +context+ to its
      # type struct.
      def self.runtime_type_cast(context, var_name)
        class_spec = context.root
        type_struct_name = type_struct_name(class_spec)
        type_object = base_type_object(context)
        real_self = "((intptr_t) #{var_name}) + #{type_object}->tp_basicsize"
        "( #{type_struct_name} * )( #{real_self} )"
      end

      # A declaration of a pointer to an instance of +class_spec+ named self.
      def self.self_declaration(class_spec)
        pointer_type = CSource::CPointer.new(type_struct_name(class_spec))
        CSource::CDeclaration.new(pointer_type, 'self')
      end

      # The type of the C function wrapped by the function at the root of
      # +context+.
      def self.source_return_type(context)
        return_type = context.root[:c].return_type

        if return_type.to_s == EQUIVALENT_STRUCT_KEYWORD
          C.equivalent_struct(context.parent.root)
        elsif return_type.to_s == EQUIVALENT_POINTER_KEYWORD
          C.equivalent_pointer(context.parent.root)
        elsif return_type == CSource::CType.new('bool')
          CSource::CType.new('long')
        else
          return_type
        end
      end

      # Gives the name of the type object instance for a given class.
      def self.type_object_name(class_spec)
        "#{class_spec.snake_case_name}_type_object"
      end

      # Gives the name of the type struct for a given class.
      def self.type_struct_name(class_spec)
        "#{class_spec.snake_case_name}_type_struct"
      end

      # Generates a PythonSourceSet for a Python library wrapping a +context+
      # with a Namespace root.
      def self.wrap_namespace_context(context)
        name = Python.module_name(context.root)
        set = PythonSource::PythonSourceSet.new(name)

        set.add_module_source(define_module(context))

        C.libraries(context).each do |it|
          set.add_link(it)
        end

        set
      end

      # An +Array+ of C source to check for errors after the wrapped call in
      # the function at the root of +context+.
      def self.wrapped_error_check(context)
        func_spec = context.root

        # TODO: check to make sure the root is a FunctionSpec

        return [] unless func_spec[:c].error_check?

        action = func_spec[:c].error_action
        exception_class = context.resolve_name(action.type.name_words).root
        type_object = "(PyObject *) &#{type_object_name(exception_class)}"

        checks = func_spec[:c].error_rules.map do |rule|
          resolved_vals = rule.vals.map do |it|
            resolve_action_value(context.parent, it)
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
                          exception_class.parent
                        else
                          exception_class
                        end
          cast = runtime_type_cast(equiv_class, 'exception_obj')
          blk.puts("#{type_struct_name(equiv_class)} *subtype = #{cast};")

          value_variable = resolve_action_value(context.parent, action.value)
          blk.puts("subtype->equivalent = #{value_variable};")
          blk.puts("PyErr_SetObject(#{type_object}, exception_obj );")
          # TODO: need to detect whether a different error return is needed,
          # for example -1
          blk.puts('return NULL;')
        end

        [check_blk]
      end

      # The expression containing the call to the C function wrapped by the
      # function at the root of +context+.
      def self.wrapped_function_call(context)
        func_spec = context.root
        resolved_params = func_spec[:c].params.map do |param|
          resolve_wrapped_param(context, param)
        end

        call = "#{func_spec[:c].name}( #{resolved_params.join(', ')} )"

        if func_spec.constructor?
          "#{class_struct_pointer(context.parent)} = #{call}"
        elsif func_spec[:c].error_check? || !func_spec.void_return?
          "return_val = #{call}"
        else
          call
        end
      end

      # Declares the local variables used to pass parameters to the wrapped
      # function for the function at the root of +context+.
      def self.wrapper_param_locals(context)
        func_spec = context.root
        func_spec.params.map do |param_spec|
          param_type = param_spec.type
          local_type = if param_type.equivalent_struct?
                         C.equivalent_struct(context.parent.root)
                       elsif param_spec.type.equivalent_pointer?
                         C.equivalent_pointer(context.parent.root)
                       else
                         name_words = Named.words_from_name(param_type.base)
                         class_name = Named.upper_camel_case_name(name_words)
                         type_context = context.resolve do |it|
                           it.root.upper_camel_case_name == class_name
                         end

                         if type_context.nil?
                           CSource::CType.new(param_spec.type.name)
                         else
                           struct_name = type_struct_name(type_context.root)
                           CSource::CPointer.new(struct_name)
                         end
                       end

          CSource::CDeclaration.new(local_type, param_spec.name)
        end
      end

      # The return type of the wrapper for +func_spec+.
      def self.wrapper_return_type(func_spec)
        if func_spec.constructor?
          'int'
        else
          CSource::CPointer.new('PyObject')
        end
      end
    end
  end
end
