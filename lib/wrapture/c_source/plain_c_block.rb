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

module Wrapture
  module CSource
    # A plain block is just a source tree and nothing else.
    #
    # This will become a Data class once minimum support is Ruby 3.2.
    class PlainCBlock
      include CBlock

      # The source tree for this block.
      attr_reader :tree

      # A plain block can be created with or without anything in the source
      # tree.
      def initialize(tree: [])
        @tree = tree
      end
    end
  end
end
