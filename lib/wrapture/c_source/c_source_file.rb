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

require 'wrapture/source_file'

module Wrapture
  module CSource
    # A C source file.
    class CSourceFile < SourceFile
      include CBlock

      # The source tree of this file.
      attr_reader :tree

      # A newly created C source file has an empty tree.
      def initialize(*args)
        super
        @tree = []
      end

      # The source file contents. This is equivalent to the formatted C source
      # tree for this file.
      def contents
        CSource.format_block(@tree)
      end
    end
  end
end
