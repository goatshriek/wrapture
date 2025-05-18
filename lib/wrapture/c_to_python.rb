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

    # Get the name of the type object for the given class's base, if one exists.
    def self.base_type_object(class_spec)
      if class_spec.child? && class_spec.parent_spec
        return "(&#{type_object_name(class_spec.parent_spec)})"
      end

      return '(( PyTypeObject *) PyExc_Exception)' if class_spec.exception?

      nil
    end

    # Returns a cast of the equivalent member of an instance of the given class
    # with the given name to the given type.
    def self.cast_equivalent(class_spec, var_name, to)
      struct = "struct #{class_spec.struct.name}"

      if [EQUIVALENT_STRUCT_KEYWORD, struct].include?(to)
        "#{'*' if class_spec.pointer_wrapper?}#{var_name}->equivalent"
      elsif [EQUIVALENT_POINTER_KEYWORD, "#{struct} *"].include?(to)
        "#{'&' unless class_spec.pointer_wrapper?}#{var_name}->equivalent"
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

    # The parameters used for a constructor wrapper.
    def self.constructor_params
      type_object_ptr = CSource::CPointer.new('PyTypeObject')
      pyobject_ptr = CSource::CPointer.new('PyObject')

      [CSource::CDeclaration.new(type_object_ptr, 'type'),
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
    # given source block, and performs any setup needed on it. Assumes that the
    # type variable has a pointer to the PyTypeObject structure for the class.
    #
    # This is useful for constructors that need to construct the self instance
    # before calling the wrapped function with the instance.
    def self.create_self(blk, class_spec)
      self_type = "#{type_struct_name(class_spec)} *"
      blk.puts("self = ( #{self_type} ) type->tp_alloc( type, 0 );")
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

    # Declares the local variables used in the wrapper for the given function in
    # the given block.
    def self.declare_wrapper_locals(blk, func_spec)
      if !func_spec.overloaded? &&
         (func_spec.constructor? || runtime_class?(func_spec.owner))
        blk << self_declaration(func_spec.owner)
        blk.puts(';')
      end

      if func_spec.params? && !func_spec.overloaded?
        blk.declare('int', 'parse_result')
      end

      if !func_spec.void_return? || func_spec.wrapped.use_return?
        effective_return = func_spec.wrapped.return_val_type
        if effective_return.name == 'void'
          effective_return = func_spec.return_type
        end
        effective_return = func_spec.resolve_type(effective_return)

        effective_return = 'long' if effective_return.name == 'bool'

        blk.declare(effective_return, 'return_val')
      end

      declare_wrapper_param_locals(blk, func_spec) unless func_spec.overloaded?
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

    # The default constructor for a class that does not have one defined.
    def self.default_constructor(class_spec)
      name = "#{class_spec.snake_case_name}_new"
      params = constructor_params
      return_type = Wrapture::CSource::CPointer.new('PyObject')

      f = CSource::CFunction.new(name, params: params, return_type: return_type,
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

    # Generates a source file with the definition of a module for a scope.
    def self.define_module(scope)
      src = CSource::CSourceFile.new("#{scope.name}.c")

      src.puts('#define PY_SSIZE_T_CLEAN')
      src.include('Python.h')

      # offsetof is only needed for the member definition for constants
      if scope.classes.any? { |class_spec| !class_spec.constants.empty? }
        src.include('stddef.h', comment: 'for offsetof()')
      end

      scope.definition_includes.each { |inc| src.include(inc) }

      declare_module_struct(src, scope)

      scope.classes.each do |class_spec|
        src << class_type_struct(class_spec)
        src.declare('PyTypeObject', type_object_name(class_spec),
                    attributes: ['static'])

        next unless class_spec.factory?

        # TODO: do we need this forward declaration?
        src << factory_constructor(class_spec).declaration
        src << ";\n"
      end

      scope.classes.select(&:factory?).each do |class_spec|
        src << factory_constructor(class_spec)
      end

      overload_groups = {}
      scope.classes.each do |class_spec|
        unless class_spec.functions.any?(&:constructor?)
          src << default_constructor(class_spec)
        end

        unless class_spec.functions.any?(&:destructor?)
          src << default_destructor(class_spec)
        end

        class_spec.functions.each do |func_spec|
          src << function_wrapper(func_spec)

          # collect the overloads to define the dispatcher later
          if func_spec.overloaded?
            if overload_groups.include?(func_spec.name)
              overload_groups[func_spec.name] << func_spec
            else
              overload_groups[func_spec.name] = [func_spec]
            end
          end
        end
      end

      overload_groups.each_value do |funcs|
        src << overload_dispatcher(funcs)
      end

      src.puts('// START LEGACY WRAPPER CODE')
      wrapper = CToPythonWrapper.new(scope)
      wrapper.define_module do |line|
        src.puts(line)
      end
      src.puts('// END LEGACY WRAPPER CODE')

      scope.classes.each do |class_spec|
        src << class_methods_declaration(class_spec)
        src << ";\n"
        src << class_members_declaration(class_spec)
        src << ";\n"
        src << class_type_object_declaration(class_spec)
        src << ";\n"
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

    # The function wrapper for a given function.
    #
    # For destructors, this function is equivalent to calling
    # +destructor_wrapper+.
    #
    # For functions that are overloaded, this function is equivalent to calling
    # +overload_wrapper+.
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

    # The name of the function that will be defined to wrap the given function.
    def self.function_wrapper_name(func_spec)
      base = func_spec.owner.snake_case_name
      method_name = if func_spec.constructor?
                      'new'
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

    # The Python member type symbol to use for this type, suitable for use with
    # the PyMemberDef.type struct field.
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

    # A function wrapper for a function that does not have an parameters.
    def self.no_args_wrapper(func_spec)
      name = function_wrapper_name(func_spec)
      runtime_class = runtime_class?(func_spec.owner)
      pyobject_ptr = CSource::CPointer.new('PyObject')
      unused_args = CSource::CDeclaration.new(pyobject_ptr,
                                              'Py_UNUSED( ignored )')
      params = if func_spec.constructor?
                 constructor_params
               elsif runtime_class
                 [CSource::CDeclaration.new('void *', 'runtime_self'),
                  unused_args]
               else
                 [self_declaration(func_spec.owner), unused_args]
               end

      f = CSource::CFunction.new(name, params: params,
                                       return_type: pyobject_ptr,
                                       attributes: ['static'])
      declare_wrapper_locals(f, func_spec)

      if func_spec.constructor?
        create_self(f, func_spec.owner)
      elsif runtime_class
        self_cast = runtime_type_cast(func_spec.owner, 'runtime_self')
        f.puts("self = #{self_cast};")
      end

      f.puts("#{wrapped_function_call(func_spec)};")
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

      funcs.flat_map { |it| wrapper_param_locals(it) }.uniq.each do |param_decl|
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

    # The name of the function that will be defined to wrap the given function.
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
    # function. Expects @spec to be a function spec when called.
    def self.param_uses_equivalent?(func_spec, wrapped_param)
      param = func_spec.params.find { |p| p.name == wrapped_param['value'] }

      !param.nil? &&
        !wrapped_param['type'].nil? &&
        func_spec.owner.type?(param.type)
    end

    # The expression containing the call to the PyArg_ParseTuple.
    def self.parse_tuple_call(func_spec)
      format_str = "\"#{arg_parse_format(func_spec)}\""
      arg_vars = wrapper_param_locals(func_spec).map { |decl| "&#{decl.name}" }
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

      create_self(f, func_spec.owner) if func_spec.constructor?

      f.puts("#{wrapped_function_call(func_spec)};")
      f.puts(return_statement(func_spec))

      f
    end

    # Gives an expression for using a given parameter.
    # Equivalent structs and pointers are resolved, as well as casts between
    # types if they are known within the scope of this function.
    def self.resolve_wrapped_param(func_spec, param_hash)
      used_param = func_spec.params.find { |p| p.name == param_hash['value'] }

      if param_hash['value'] == EQUIVALENT_STRUCT_KEYWORD
        class_struct(func_spec.owner)
      elsif param_hash['value'] == EQUIVALENT_POINTER_KEYWORD
        class_struct_pointer(func_spec.owner)
      elsif param_hash['value'] == '...'
        'variadic_args'
      elsif param_uses_equivalent?(func_spec, param_hash)
        param_class = func_spec.owner.type(used_param.type)
        cast_equivalent(param_class, used_param.name, param_hash['type'])
      else
        param_hash['value']
      end
    end

    # The return statement used in this function's definition.
    def self.return_statement(func_spec)
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
    # its associated type information are not available until runtime.
    def self.runtime_class?(class_spec)
      class_spec.exception?
    end

    # A cast of a runtime type to the class type struct.
    def self.runtime_type_cast(class_spec, var_name)
      type_struct_name = type_struct_name(class_spec)
      type_object = base_type_object(class_spec)
      real_self = "((intptr_t)#{var_name}) + #{type_object}->tp_basicsize"
      "( #{type_struct_name} * )( #{real_self} )"
    end

    # A declaration of the self pointer for a class.
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
      build = PythonBuild.new(scope.name)

      build.add_module_source(define_module(scope))

      scope.libraries.each do |lib|
        build.add_link(lib)
      end

      build
    end

    # The expression containing the call to the underlying wrapped function.
    def self.wrapped_function_call(func_spec)
      resolved_params = func_spec.wrapped.params.map do |param|
        resolve_wrapped_param(func_spec, param)
      end

      call = "#{func_spec.wrapped.name}( #{resolved_params.join(', ')} )"

      if func_spec.constructor?
        "#{class_struct_pointer(func_spec.owner)} = #{call}"
      elsif func_spec.wrapped.error_check? || !func_spec.void_return?
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
