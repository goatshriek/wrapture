# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020 Joel E. Anderson
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
  # A description of a type used in a specification.
  class TypeSpec
    # Returns a normalized copy of the hash specification of a type in +spec+.
    # See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes the hash specification of a type in +spec+ in place. This will
    # normalize the include list.
    def self.normalize_spec_hash!(spec)
      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec
    end

    # Creates a parameter specification based on the provided hash +spec+.
    # +spec+ can be a string instead of a hash, in which case it will be used
    # as the name of the type.
    def initialize(spec = 'void')
      actual_spec = if spec.is_a?(String)
                      { 'name' => spec }
                    else
                      spec
                    end

      @spec = TypeSpec.normalize_spec_hash(actual_spec)
    end

    # Creates a new TypeSpec within the scope of +owner+ that will be directly
    # usable. This will replace equivalent structs, pointers, and self
    # references with a usable type name.
    def absolute(owner)
      owner.resolve_type(self)
    end

    # The name of this type with all special characters removed.
    def base
      name.delete('*&').strip
    end

    # True if this type is an equivalent struct pointer reference.
    def equivalent_pointer?
      name == EQUIVALENT_POINTER_KEYWORD
    end

    # True if this type is an equivalent struct reference.
    def equivalent_struct?
      name == EQUIVALENT_STRUCT_KEYWORD
    end

    # True if this type is a function.
    def function?
      @spec.key?('function')
    end

    # A list of includes needed for this type.
    def includes
      @spec['includes']
    end

    # The name of the type.
    def name
      @spec['name']
    end

    # True if this type is a pointer.
    def pointer?
      name.end_with?('*')
    end

    # A string with a declaration of FunctionSpec +func+ with this type as the
    # return value. +func_name+ can be provided to override the function name,
    # for example if a class name needs to be included.
    def return_expression(func, func_name: func.name)
      name_part = String.new(func_name || '')
      param_part = String.new
      ret_part = name

      current_spec = @spec
      while current_spec.is_a?(Hash) && current_spec.key?('function')
        name_part.prepend('( *')

        temp_func_spec = FunctionSpec.new(current_spec['function'])
        param_part.concat(" )( #{temp_func_spec.param_list} )")

        current_spec = current_spec.dig('function', 'return', 'type')
        ret_part = current_spec
      end

      ret_part << ' ' unless ret_part.end_with?('*')

      "#{ret_part}#{name_part}( #{func.param_list} )#{param_part}"
    end

    # True if this type is a reference to a class instance.
    def self?
      name == SELF_REFERENCE_KEYWORD
    end

    # A string with a declaration of a variable named +var_name+ of this type.
    def variable(var_name = nil)
      if variadic?
        '...'
      elsif var_name.nil?
        name
      elsif function?
        func = @spec['function']
        return_spec = FunctionSpec.normalize_return_hash(func['return'])
        return_portion = TypeSpec.new(return_spec['type']).name
        "#{return_portion} ( *#{var_name} )( #{param_list} )"
      else
        "#{name}#{' ' unless name.end_with?('*')}#{var_name}"
      end
    end

    # True if this type is a variadic parameter type (name is equal to +...+).
    def variadic?
      name == '...'
    end

    private

    # The parameter list of this function pointer.
    def param_list
      var_list = @spec['function'].fetch('params', []).map do |param|
        TypeSpec.new(param['type']).variable(param.fetch('name', nil))
      end

      var_list.join(', ')
    end
  end
end
