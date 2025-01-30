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
        when CBlock
          format_block(node)
        else
          "#{node}\n"
        end
      end
    end
  end
end
