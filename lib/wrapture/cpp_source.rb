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

      cls.constructors.each do |it|
        decl = format_constructor_declaration(it) + [";\n"]
        src += Wrapture::CSource.indent(decl)
      end

      unless cls.destructor.nil?
        src += Wrapture::CSource.indent(['~', cls.name, '(void);'])
      end

      public_member_functions = cls.member_functions.select do |it|
        it.accessibility == :public
      end

      public_member_functions.each do |it|
        decl = format_member_function_declaration(it) + [";\n"]
        src += Wrapture::CSource.indent(decl)
      end

      cls.data_members.each do |it|
        decl = format_declaration(it) + [";\n"]
        src += Wrapture::CSource.indent(decl)
      end

      src << '} /* class '
      src << cls.name
      src << ' */'

      src
    end

    # Formats the definition of a C++ class into a set of source file strings.
    def self.format_class_definition(cls)
      src = []
      cls.constructors.each do |constructor_func|
        src.concat(format_constructor_definition(constructor_func))
        src << "\n\n"
      end

      unless cls.destructor.nil?
        src.concat(format_destructor_definition(cls.name, cls.destructor))
        src << "\n\n"
      end

      cls.member_functions.each do |member_func|
        src.concat(format_member_function_definition(cls.name, member_func))
        src << "\n\n"
      end

      src
    end

    # Formats the declaration of a C++ constructor into a set of source file
    # strings. This is subtly different from method declarations, which have
    # return types.
    def self.format_constructor_declaration(func)
      src = [func.name, '(']

      if func.params.empty?
        src << 'void'
      else
        func.params.each do |param_decl|
          src += format_declaration(param_decl)
          src << ', '
        end

        # get rid of the trailing comma
        src.pop
      end

      src << ')'
    end

    # Formats the definition of a C++ constructor into a set of source file
    # strings. This is subtly different from method definitions, which have
    # return types and do not have initializer lists.
    #
    # The function name is assumed to be the class name.
    def self.format_constructor_definition(func)
      src = [func.name, '::']
      src += format_constructor_declaration(func)
      src << "{\n"
      src += Wrapture::CSource.indent(format_block(func))
      src << '}'
    end

    # Formats a declaration into a set of source code strings.
    def self.format_declaration(decl)
      if decl.is_a?(CSource::CDeclaration)
        return CSource.format_declaration(decl)
      end

      src = [decl.cpp_type.name]

      src += [' ', decl.name] unless decl.name.nil?

      src
    end

    # Formats the definition of a destructor into a set of source code strings.
    def self.format_destructor_definition(class_name, func)
      src = [class_name, '::', func.name, "(void){\n"]
      src += Wrapture::CSource.indent(format_block(func))
      src << '}'

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

    # Formats a member function declaration into a set of source file strings.
    def self.format_member_function_declaration(func)
      src = []

      src << 'static ' if func.static?

      src += format_declaration(CppDeclaration.new(func.return_type))
      src += [' ', func.name, '(']

      if func.params.empty?
        src << 'void'
      else
        func.params.each do |param_decl|
          src += format_declaration(param_decl)
          src << ', '
        end

        # get rid of the trailing comma
        src.pop
      end

      src + [')']
    end

    # Formats a member function definition into a set of source file strings.
    def self.format_member_function_definition(class_name, func)
      src = format_declaration(CppDeclaration.new(func.return_type))
      src += [' ', class_name, '::', func.name, '(']

      if func.params.empty?
        src << 'void'
      else
        func.params.each do |param_decl|
          src += format_declaration(param_decl)
          src << ', '
        end

        # get rid of the trailing comma
        src.pop
      end

      src << "){\n"
      src += Wrapture::CSource.indent(format_block(func))
      src << '}'
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
