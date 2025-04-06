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
require 'wrapture/c_source/c_pointer'
require 'wrapture/c_source/c_source_file'
require 'wrapture/c_source/c_struct'
require 'wrapture/c_source/c_type'
require 'wrapture/c_source/plain_c_block'

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
          format_declaration(node)
        when CStruct
          format_struct(node)
        when CFunction
          format_function_definition(node)
        when CIf
          format_if(node)
        when CBlock
          format_block(node)
        else
          "#{node}\n"
        end
      end
    end

    # Formats a declaration into a set of source code strings.
    def self.format_declaration(decl)
      name = decl.name
      c_type = decl.c_type

      if c_type.is_a?(CPointer)
        name = "*#{name}"
        c_type = c_type.c_type
      end

      case c_type
      when CFunction
        return format_function_declaration(c_type) + [";\n"]
      end

      type_name = case c_type
                  when CStruct
                    if c_type.typedef.empty?
                      "struct #{c_type.name}"
                    else
                      c_type.typedef
                    end
                  else
                    c_type.to_s
                  end

      stmt = []
      stmt << "#{decl.attributes.join(' ')} " unless decl.attributes.empty?
      stmt << "#{type_name} #{name}"
      if decl.initialized?
        stmt += [' = '] + format_initialization(decl) + [";\n"]
      end

      stmt
    end

    # Formats a function declaration into a set of source code strings.
    def self.format_function_declaration(func)
      strs = []

      return_type_decl = CDeclaration.new(func.return_type, '')
      strs += format_declaration(return_type_decl)
      strs << "\n"
      strs << func.name
      strs << '( '

      strs << if func.params.empty?
                ' void '
              else
                func.params.map do |p|
                  format_declaration(p)
                end.join(', ')
              end

      strs << ' )'
    end

    # Formats a function definition into a set of source code strings.
    def self.format_function_definition(func)
      strs = format_function_declaration(func)
      strs << "{\n"
      strs += indent(func.tree)

      unless func.fail_labels.empty?
        strs << "\n"
        func.fail_labels.reverse.map do |label|
          expr = "#{label[0]}:\n"
          expr += "  #{label[1]}\n" unless label[1].empty?
          strs << expr
        end
      end

      strs << "}\n"
    end

    # Formats an if-else block.
    def self.format_if(if_condition)
      src = ['if( ', if_condition.condition, " ){\n"]
      src += indent(if_condition.if_block.tree)
      src << '}'

      else_block = if_condition.else_block
      case else_block
      when CIf
        src + [' else '] + format_if(else_block)
      when nil
        src + ["\n"]
      else
        src + [' else {'] + indent(format_block(else_block.tree)) + ["}\n"]
      end
    end

    # Formats the initialization of a declaration.
    def self.format_initialization(decl)
      stmts = decl.value.flat_map do |val|
        if val.is_a?(CDeclaration)
          format_initialization(val) + [",\n"]
        else
          suffix = if val.is_a?(String) && val.start_with?('.')
                     ",\n"
                   else
                     "\n"
                   end

          [val, suffix]
        end
      end
      stmts.pop # trim off the last suffix
      ["{\n"] + indent(stmts) + ['}']
    end

    # Formats a struct definition into a set of source code strings.
    def self.format_struct(c_struct)
      src = ["struct #{c_struct.name} {\n"]

      c_struct.members.each do |member|
        src += indent(format_block([member]) + [";\n"])
      end

      src << '}'

      unless c_struct.typedef.empty?
        src.prepend('typedef ')
        src.append(" #{c_struct.typedef}")
      end

      src << ";\n"
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
