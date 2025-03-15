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
      # The name of the struct.
      attr_reader :name

      # The members of the struct.
      attr_reader :members

      # The typedef name of the struct. If this is empty, then there is no
      # typedef for this struct.
      attr_reader :typedef

      # Creates a CStruct from a struct spec.
      def self.from_spec(struct_spec)
        new(name: struct_spec.name)
      end

      # Creates a type for the base type given.
      def initialize(name: '', members: [], typedef: '')
        @name = name
        @members = members
        @typedef = typedef
      end
    end
  end
end
