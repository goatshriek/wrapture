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
    # A conditional if check and block, optionally with an accompanying else
    # block as well.
    class CIf
      # The condition checked in the if statement.
      attr_reader :condition

      # The block executed when the if condition is true.
      attr_accessor :if_block

      # The else block for when the if condition is not true. This may be nil
      # if there is no else block accompanying the if, or another if block to
      # create an else if structure.
      attr_accessor :else_block

      # An if block takes a string condition, and provides a CBlock to the block
      # of the constructor that will be the body of the if statement when the
      # condition is met. If a block is not provided, then it will be empty
      # after creation.
      def initialize(condition, &block)
        @condition = if condition.is_a?(String)
                       CExpression.new(condition)
                     else
                       condition
                     end
        @if_block = PlainCBlock.new
        @else_block = nil

        block&.call(@if_block)
      end

      # Calls the provided block with a CBlock that will be executed when the
      # condition for this block is not met in an else statement.
      def else(&block)
        @else_block = PlainCBlock.new
        block.call(@else_block)
        self
      end

      # Calls the provided block with a CBlock that will be executed when the
      # previous conditions for this block are not met, but this one is. The
      # new CIf is returned.
      def else_if(condition, &block)
        @else_block = CIf.new(condition, &block)
        @else_block
      end
    end
  end
end
