# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2026 Joel E. Anderson
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
  module CppSource
    # A reference to a type used in C++ source code.
    class CppReference
      # The type the reference contains.
      attr_reader :cpp_type

      # A reference has a base type.
      def initialize(cpp_type)
        @cpp_type = case cpp_type
                    when String
                      CppType.new(cpp_type)
                    else
                      cpp_type
                    end
      end

      # Compares with another reference.
      def ==(other)
        return false unless other.is_a?(CppReference)

        @cpp_type == other.cpp_type
      end

      # Alias to support Enumerable#uniq.
      alias eql? ==

      # The includes needed to use this reference type.
      def includes
        @cpp_type.includes.dup
      end

      # A String representation of this reference.
      def to_s
        "reference to #{@cpp_type}"
      end
    end
  end
end
