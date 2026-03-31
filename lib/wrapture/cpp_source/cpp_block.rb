# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025-2026 Joel E. Anderson
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
    # A block of C++ source code.
    #
    # Blocks have a +tree+ attribute which is an array representing the syntax
    # tree of the items in the block. The tree contents could be anything
    # including Strings, C++ source objects, and other blocks.
    module CppBlock
      # Adds +element+ directly to the source tree. Nil elements are ignored.
      def <<(element)
        tree << element unless element.nil?
        self
      end

      # Add a variable declaration statement to the block. The declaration is
      # created using the supplied arguments passed directly to the CDeclaration
      # constructor, followed by a semicolon and newline.
      def declare(*args, **kwargs)
        tree << CppDeclaration.new(*args, **kwargs)
        tree << ";\n"
        self
      end

      # Add an if condition to the block. The newly created if block is
      # returned, allowing a chained call to else if needed.
      def if(condition, &block)
        if_condition = CIf.new(condition, &block)
        tree << if_condition

        if_condition
      end

      # Add an include to the block. The include is created using the supplied
      # arguments passed directly to the CInclude constructor.
      def include(*args, **kwargs)
        tree << CInclude.new(*args, **kwargs)
        self
      end

      # Adds raw strings directly to the block.
      def puts(*parts)
        parts.each do |line|
          tree << line
          tree << "\n"
        end

        tree << "\n" if parts.empty?

        self
      end
    end
  end
end
