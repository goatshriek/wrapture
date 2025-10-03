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

require 'wrapture/cpp_source/cpp_class'
require 'wrapture/cpp_source/cpp_function'
require 'wrapture/cpp_source/cpp_source_file'
require 'wrapture/cpp_source/cpp_source_set'

module Wrapture
  # Classes and utilities for working with C++ source code.
  module CppSource
    # Formats a C++ class into a set of source file strings.
    def self.format_class(cls)
      src = ['class ', cls.name]
      src << " : #{cls.parent_name}" unless cls.parent_name.nil?
      src << " {\npublic:\n} /* class "
      src << cls.name
      src << ' */'

      src
    end

    # Formats a syntax tree of C++ source elements into a set of source file
    # strings.
    def self.format_tree(tree)
      tree.flat_map do |node|
        case node
        when CppClass
          format_class(node)
        else
          # fall back to the C source formatting for everthing else
          CSource.format_block([node])
        end
      end
    end
  end
end
