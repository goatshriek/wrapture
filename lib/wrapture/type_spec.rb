# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020-2026 Joel E. Anderson
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
  # A description of a type.
  #
  # TypeSpec is an abstraction of types in source languages. It is separate from
  # language-specific types that are defined in source language modules like
  # CSource::CType.
  class TypeSpec
    include Named

    # The name used for the Any type, where any type is valid.
    ANY_TYPE_NAME = %w[any].freeze

    # The name used for the Self type, which references the class type of the
    # context.
    SELF_TYPE_NAME = %w[self].freeze

    # The name used for the Void type, a type that cannot be instantiated.
    VOID_TYPE_NAME = %w[void].freeze

    # The name words that make up the parameter name.
    attr_reader :name_words

    # Creates a new ParamSpec from the hash +spec_hash+.
    #
    # The hash must have a +:name+ key with a String or Enumerable of strings as
    # the value, which will be used as the name of the TypeSpec.
    def self.from_hash(spec_hash)
      unless spec_hash.key?(:name)
        raise(MissingSpecKey, 'ParamSpec hashes must have a :name key')
      end

      new(spec_hash[:name])
    end

    # Creates a type specification based on the provided hash +spec+.
    # +spec+ can be a string instead of a hash, in which case it will be used
    # as the name of the type.
    #
    # Type specs must have a 'name' key with either the type itself (for example
    # 'const char *') or a keyword specifying some other type (for example
    # 'equivalent_struct'). The only exception is for function pointers, which
    # instead use a 'function' key that contains a FunctionSpec specification.
    # This specification does not need to be definable, it only needs to have
    # a parameter list and return type for the signature to be clear.
    def initialize(name)
      @name_words = Named.words_from_name(name)
    end

    # Compares this TypeSpec with +other+. Comparison happens by converting each
    # object to a string using to_s and comparing.
    #
    # Added in release 0.4.2.
    def ==(other)
      @name_words == other.name_words
    end

    # True if this is the any type.
    def any?
      @name_words == ANY_TYPE_NAME
    end

    # The name of this type with all special characters and keywords removed.
    def base
      name.delete('*&').delete_prefix('struct').strip
    end

    # True if this type is an equivalent struct pointer reference.
    def equivalent_pointer?
      snake_case_name == EQUIVALENT_POINTER_KEYWORD
    end

    # True if this type is an equivalent struct reference.
    def equivalent_struct?
      snake_case_name == EQUIVALENT_STRUCT_KEYWORD
    end

    # True if this type is a function.
    def function?
      @spec.key?(:function)
    end

    # A new FunctionSpec instance from this type, or nil if it is not a
    # function.
    def function
      FunctionSpec.from_hash(@spec[:function]) if function?
    end

    # A list of includes needed for this type.
    def includes
      includes = @spec[:includes].dup
      includes.concat(function.declaration_includes) if function?
      includes.uniq
    end

    # True if this type is a pointer.
    def pointer?
      name.end_with?('*')
    end

    # True if this type is the self type.
    def self?
      @name_words == SELF_TYPE_NAME
    end

    # Gives a string representation of this type (its name).
    #
    # Added in release 0.4.2.
    def to_s
      upper_camel_case_name
    end

    # True if this is the void type.
    def void?
      @name_words == VOID_TYPE_NAME
    end
  end
end
