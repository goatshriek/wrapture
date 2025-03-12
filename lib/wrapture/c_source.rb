# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

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

require 'wrapture/c_source/c_block'
require 'wrapture/c_source/c_declaration'
require 'wrapture/c_source/c_function'
require 'wrapture/c_source/c_if'
require 'wrapture/c_source/c_include'
require 'wrapture/c_source/c_source_file'
require 'wrapture/c_source/c_struct'
require 'wrapture/c_source/c_type'

module Wrapture
  # Classes and utilities for working with C source code.
  module CSource
    # Formats a syntax tree of C source elements into a set of source file
    # strings.
    def self.format_block(tree)
      tree.flat_map do |node|
        case node
        when String
          node
        when CDeclaration
          attr = node.attributes.join(' ')
          decl = "#{attr} struct #{node.c_type.name} #{node.name}"

          if node.initialized?
            vals = node.value.join(",\n  ")
            [decl, " = {\n  ", vals, "\n};\n"]
          else
            [decl, ";\n"]
          end
        when CStruct
          decl = ["struct #{node.name} {\n  ", node.members.join(";\n  "),
                  ";\n}"]

          unless node.typedef.empty?
            decl.prepend('typedef ')
            decl.append(" #{node.typedef}")
          end

          decl << ";\n"
        when CFunction
          format_function(node)
        when CIf
          format_if(node)
        when CBlock
          format_block(node)
        else
          "#{node}\n"
        end
      end
    end

    # Formats a function definition into a set of source code strings.
    def self.format_function(func)
      [func.return_type, "\n", func.name, "( void ){\n"] +
        indent(func.tree) +
        ["\n"] + func.fail_labels.reverse.map do |label|
                   expr = "#{label[0]}:\n"
                   expr += "  #{label[1]}\n" unless label[1].empty?
                   expr
                 end + ["}\n"]
    end

    # Formats an if-else block.
    def self.format_if(if_condition)
      # TODO: add else block handling
      ['if( ', if_condition.condition, " ){\n"] +
        indent(if_condition.if_block.tree) +
        ["}\n"]
    end

    # Adds indentation to the given tree of source chunks. This is done by
    # adding spaces on lines that are not empty.
    def self.indent(tree)
      format_block(tree).join.split("\n").map do |line|
        if line.empty?
          "\n"
        else
          "  #{line}\n"
        end
      end
    end
  end
end
