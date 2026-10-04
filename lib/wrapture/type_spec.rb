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

    # The name used for the integer type.
    INT_TYPE_NAME = %w[int].freeze

    # The name used for the Self type, which references the class type of the
    # context.
    SELF_TYPE_NAME = %w[self].freeze

    # The name used for the string type.
    STRING_TYPE_NAME = %w[string].freeze

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

    # True if +spec+ is an instance of this type.
    def ===(spec)
      return true if any?

      spec.name_words == name_words
    end

    # True if this is the any type.
    def any?
      @name_words == ANY_TYPE_NAME
    end

    # True if this is an integer type.
    def int?
      @name_words == INT_TYPE_NAME
    end

    # True if this type is the self type.
    def self?
      @name_words == SELF_TYPE_NAME
    end

    # True if this type is the string type.
    def string?
      @name_words == STRING_TYPE_NAME
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
