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
    # A struct type used in C source code.
    class CStruct
      # The includes needed to use this function.
      attr_reader :includes

      # The name of the struct.
      attr_reader :name

      # The members of the struct.
      attr_reader :members

      # The typedef name of the struct. If this is empty, then there is no
      # typedef for this struct.
      attr_reader :typedef

      # Creates a new C struct from a hash.
      def self.from_hash(spec)
        unless spec.key?(:name)
          raise MissingSpecKey, 'a name is required for c structs'
        end

        c_struct = new(name: spec[:name])

        if spec.key?(:includes)
          c_struct.includes.concat(Wrapture.normalize_array(spec[:includes]))
        end

        if spec.key?(:members)
          spec[:members].each do |member|
            c_struct.members << CDeclaration.new(member[:type], member[:name])
          end
        end

        c_struct
      end

      # Creates a CStruct from a struct spec.
      def self.from_spec(struct_spec)
        new(name: struct_spec.name)
      end

      # Creates a type for the base type given.
      def initialize(name: '', members: [], typedef: '')
        @includes = []
        @name = name
        @members = members
        @typedef = typedef
      end

      # Compares with another struct.
      def ==(other)
        @name == other.name &&
          @members == other.members &&
          @typedef == other.typedef
      end

      # Alias to support Enumerable#uniq.
      alias eql? ==
    end
  end
end
