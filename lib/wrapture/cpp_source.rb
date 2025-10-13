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

require 'wrapture/cpp_source/cpp_block'
require 'wrapture/cpp_source/cpp_class'
require 'wrapture/cpp_source/cpp_declaration'
require 'wrapture/cpp_source/cpp_function'
require 'wrapture/cpp_source/cpp_method'
require 'wrapture/cpp_source/cpp_source_file'
require 'wrapture/cpp_source/cpp_source_set'
require 'wrapture/cpp_source/cpp_type'

module Wrapture
  # Classes and utilities for working with C++ source code.
  module CppSource
    # Formats a CppBlock into a set of source file strings.
    def self.format_block(blk)
      format_tree(blk.tree)
    end

    # Formats the declaration of a C++ class into a set of source file strings.
    def self.format_class_declaration(cls)
      src = []
      src += format_doxygen(cls.doc) unless cls.doc.empty?
      src << 'class '
      src << cls.name
      src << " : #{cls.parent_name}" unless cls.parent_name.nil?
      src << " {\npublic:\n"

      cls.methods.select { |meth| meth.accessibility == :public }.each do |meth|
        decl = format_method_declaration(meth) + ["\n"]
        src += Wrapture::CSource.indent(decl)
      end

      src << '} /* class '
      src << cls.name
      src << ' */'

      src
    end

    # Formats the definition of a C++ class into a set of source file strings.
    def self.format_class_definition(cls)
      # TODO: implement
    end

    # Formats a declaration into a set of source code strings.
    def self.format_declaration(decl)
      src = [decl.cpp_type.name]

      src += [' ', decl.name] unless decl.name.nil?

      src
    end

    # Formats a comment as a Doxygen comment block.
    def self.format_doxygen(comment)
      src = []
      comment.format(line_prefix: ' * ',
                     first_line: '/**',
                     last_line: ' */',
                     max_line_length: 78) do |line|
                       src << line
                       src << "\n"
                     end

      src
    end

    # Formats a method declaration into a set of source file strings.
    def self.format_method_declaration(meth)
      src = format_declaration(CppDeclaration.new(meth.return_type))
      src += [' ', meth.name, '(']

      if meth.params.empty?
        src << 'void'
      else
        meth.params.each do |param_decl|
          src += format_declaration(param_decl)
          src << ', '
        end

        # get rid of the trailing comma
        src.pop
      end

      src + [');']
    end

    # Formats a syntax tree of C++ source elements into a set of source file
    # strings.
    def self.format_tree(tree)
      tree.flat_map do |node|
        case node
        when CppDeclaration
          if node.cpp_type.is_a?(CppClass)
            format_class_declaration(node.cpp_type)
          else
            # fall back to C source formatting
            CSource.format_declaration(node)
          end
        when CppClass
          format_class_definition(node)
        when CppBlock
          format_block(node)
        else
          # fall back to the C source formatting for everything else
          CSource.format_block([node])
        end
      end
    end
  end
end
