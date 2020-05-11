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
    #
    # Type specs must have a 'name' key with either the type itself (for example
    # 'const char *') or a keyword specifying some other type (for example
    # 'equivalent-struct'). The only exception is for function pointers, which
    # instead use a 'function' key that contains a FunctionSpec specification.
    # This specification does not need to be definable, it only needs to have
    # a parameter list and return type for the signature to be clear.
    def initialize(spec = 'void')
      actual_spec = if spec.is_a?(String)
                      { 'name' => spec }
                    else
                      spec
                    end

      @spec = TypeSpec.normalize_spec_hash(actual_spec)
    end

    # Compares this TypeSpec with +other+. Comparison happens by converting each
    # object to a string using to_s and comparing.
    #
    # Added in release 0.4.2.
    def ==(other)
      to_s == other.to_s
    end

    # The name of this type with all special characters removed.
    def base
      name.delete('*&').strip
    end

    # An expression casting the result of a given expression into this type.
    #
    # Added in release 0.4.2.
    def cast_expression(expression)
      "( #{variable} )( #{expression} )"
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
      includes = @spec['includes'].dup

      if function?
        func = FunctionSpec.new(@spec['function'])
        includes.concat(func.declaration_includes)
      end

      includes.uniq
    end

    # The name of the type.
    def name
      @spec['name']
    end

    # True if this type is a pointer.
    def pointer?
      name.end_with?('*')
    end

    # Creates a new TypeSpec within the scope of +owner+ that will be directly
    # usable. This will replace equivalent structs, pointers, and self
    # references with a usable type name.
    def resolve(owner)
      owner.resolve_type(self)
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

        current_func = FunctionSpec.new(current_spec['function'])
        param_part.concat(" )( #{current_func.param_list} )")

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

    # Gives a string representation of this type (its name).
    #
    # Added in release 0.4.2.
    def to_s
      name
    end

    # A string with a declaration of a variable named +var_name+ of this type.
    # If +var_name+ is nil then this will simply be a type declaration.
    def variable(var_name = nil)
      if variadic?
        '...'
      elsif function?
        func = FunctionSpec.new(@spec['function'])
        func_name = "( *#{var_name} )" || '(*)'
        func.return_expression(func_name: func_name)
      elsif var_name.nil?
        name
      else
        "#{name}#{' ' unless name.end_with?('*')}#{var_name}"
      end
    end

    # True if this type is a variadic parameter type (name is equal to +...+).
    def variadic?
      name == '...'
    end
  end
end
