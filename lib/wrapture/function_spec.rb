# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2020 Joel E. Anderson
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

require 'wrapture/constants'
require 'wrapture/errors'
require 'wrapture/scope'
require 'wrapture/wrapped_function_spec'

module Wrapture
  # A description of a function to be generated, including details about the
  # underlying implementation.
  class FunctionSpec
    # Normalizes a hash specification of a function. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and will
    # set missing keys to their default values (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup
      param_types = {}

      normalized['version'] = Wrapture.spec_version(spec)
      normalized['virtual'] = Wrapture.normalize_boolean(spec, 'virtual')

      normalized['params'] ||= []
      normalized['params'].each do |param_spec|
        param_types[param_spec['name']] = param_spec['type']
        includes = Wrapture.normalize_includes(param_spec['includes'])
        param_spec['includes'] = includes
      end

      if normalized['return'].nil?
        normalized['return'] = {}
        normalized['return']['type'] = 'void'
        normalized['return']['includes'] = []
      else
        normalized['return']['type'] ||= 'void'
        includes = Wrapture.normalize_includes(spec['return']['includes'])
        normalized['return']['includes'] = includes
      end

      overload = Wrapture.normalize_boolean(normalized['return'], 'overloaded')
      normalized['return']['overloaded'] = overload

      normalized
    end

    # Creates a function spec based on the provided function spec.
    #
    # The hash must have the following keys:
    # name:: the name of the function
    # params:: a list of parameter specifications
    # wrapped-function:: a hash describing the function to be wrapped
    #
    # Each parameter specification must have a 'name' key with the name of the
    # parameter and a 'type' key with its type. It may optionally have an
    # 'includes' key with includes that are required (for example to support the
    # type) and/or a 'doc' key with documentation of the parameter.
    #
    # The wrapped-function must have a 'name' key with the name of the function,
    # and a 'params' key with a list of parameters (each a hash with a 'name'
    # and 'type' key). Optionally, it may also include an 'includes' key with a
    # list of includes that are needed for this function to compile.
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this function
    # return:: a specification of the return value for this function
    # static:: set to true if this is a static function
    #
    # The return specification may have either a 'type' key with the name of the
    # type the function returns, and/or a 'doc' key with documentation on the
    # return value itself. If neither of these is needed, then the return
    # specification may simply be omitted.
    def initialize(spec, owner = Scope.new, constructor: false,
                   destructor: false)
      @owner = owner
      @spec = FunctionSpec.normalize_spec_hash(spec)
      @wrapped = WrappedFunctionSpec.new(spec['wrapped-function'])
      @constructor = constructor
      @destructor = destructor
    end

    # True if the function is a constructor, false otherwise.
    def constructor?
      @constructor
    end

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      includes = @spec['return']['includes'].dup
      includes.concat(param_includes)
      includes.uniq
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @wrapped.includes
      includes.concat(@spec['return']['includes'])
      includes.concat(param_includes)
      includes.uniq
    end

    # A comma-separated list of parameters and resolved types fit for use in a
    # function signature or declaration.
    def param_list
      return 'void' if @spec['params'].empty?

      params = []

      @spec['params'].each do |param|
        type = resolve_type(param['type'])
        params << ClassSpec.typed_variable(type, param['name'])
      end

      params.join(', ')
    end

    # Gives an expression for calling a given parameter within this function.
    # Equivalent structs and pointers are resolved, as well as casts between
    # types if they are known within the scope of this function.
    def resolve_wrapped_param(param_spec)
      used_param = @spec['params'].find { |p| p['name'] == param_spec['value'] }

      if param_spec['value'] == EQUIVALENT_STRUCT_KEYWORD
        @owner.this_struct
      elsif param_spec['value'] == EQUIVALENT_POINTER_KEYWORD
        @owner.this_struct_pointer
      elsif used_param &&
            @owner.type?(used_param['type']) &&
            !param_spec['type'].nil?
        param_class = @owner.type(used_param['type'])
        param_class.cast_to(used_param['name'], param_spec['type'])
      else
        param_spec['value']
      end
    end

    # The signature of the function.
    def signature
      "#{@spec['name']}( #{param_list} )"
    end

    # The declaration of the function.
    def declaration
      return signature if @constructor || @destructor

      modifier_prefix = if @spec['static']
                          'static '
                        elsif virtual?
                          'virtual '
                        else
                          ''
                        end
      "#{modifier_prefix}#{@spec['return']['type']} #{signature}"
    end

    # Gives the definition of the function to a block, line by line.
    def definition(class_name)
      yield "#{return_prefix}#{class_name}::#{signature} {"

      if @wrapped.error_check?
        yield "  #{@wrapped.return_val_type} return_val;"
        yield
      end

      call = @wrapped.call_from(self)
      call_line = if @constructor
                    "this->equivalent = #{call}"
                  elsif @wrapped.error_check?
                    "return_val = #{call}"
                  elsif returns_value?
                    "return #{return_cast(call)}"
                  else
                    call
                  end

      yield "  #{call_line};"

      if @wrapped.error_check?
        yield
        @wrapped.error_check { |line| yield "  #{line}" }
      end

      yield '}'
    end

    # True if the function is virtual.
    def virtual?
      @spec['virtual']
    end

    private

    # A list of includes needed for the parameters of the function.
    def param_includes
      includes = []

      @spec['params'].each do |param_spec|
        includes.concat(param_spec['includes'])
      end

      includes
    end

    # A resolved type name.
    def resolve_type(type)
      if type == EQUIVALENT_STRUCT_KEYWORD
        "struct #{@owner.struct_name}"
      elsif type == EQUIVALENT_POINTER_KEYWORD
        "struct #{@owner.struct_name} *"
      else
        type
      end
    end

    # The function to use to create the return value of the function.
    def return_cast(value)
      if @spec['return']['type'] == @wrapped.return_val_type
        value
      elsif @spec['return']['overloaded']
        "new#{@spec['return']['type'].chomp('*').strip} ( #{value} )"
      else
        "#{@spec['return']['type']} ( #{value} )"
      end
    end

    # The return type prefix to use for the function definition.
    def return_prefix
      if @constructor || @destructor
        ''
      elsif @spec['return']['type'].end_with?('*')
        @spec['return']['type']
      else
        "#{@spec['return']['type']} "
      end
    end

    # True if the function returns a value.
    def returns_value?
      !@constructor && !@destructor && @spec['return']['type'] != 'void'
    end
  end
end
