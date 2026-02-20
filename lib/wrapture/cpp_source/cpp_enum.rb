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
    # An enumeration class in C++ code.
    class CppEnum
      # An enumeration class has some number of elements, each of which may have
      # their own documentation and value.
      def initialize(name)
        @doc = Comment.new
        @elements = []
        @name = name
      end

      # The documentation for the enumeration class.
      attr_accessor :doc

      # The elements in the enumeration.
      attr_reader :elements

      # The name of this enumeration class.
      attr_reader :name
    end
  end
end
