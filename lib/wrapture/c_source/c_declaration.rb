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
  module CSource
    # A declaration of a type in C code.
    class CDeclaration
      # The type of the declaration. Note that this may be a variety of types,
      # and is not limited to just CType instances.
      attr_reader :c_type

      # The name of the variable to declare.
      attr_reader :name

      # An array of attributes for the declaration.
      attr_reader :attributes

      # The value of the variable to use for initialization.
      attr_reader :value

      # A declaration has a type, and optionally a name and/or value.
      def initialize(c_type, name, attributes: [], value: nil)
        @c_type = case c_type
                  when String
                    CType.new(c_type)
                  else
                    c_type
                  end
        @name = name
        @attributes = attributes
        @value = value
      end

      # Compares with another declaration.
      def ==(other)
        other.is_a?(CDeclaration) &&
          @name == other.name &&
          @value == other.value &&
          @attributes == other.attributes &&
          @c_type == other.c_type
      end

      # Alias to support Enumerable#uniq.
      alias eql? ==

      # True if the declaration is initialized (that is, if it has a value).
      def initialized?
        !@value.nil?
      end
    end
  end
end
