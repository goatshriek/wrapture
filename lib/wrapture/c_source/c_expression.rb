# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2026 Joel E. Anderson
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
    # A value or operator and its arguments.
    class CExpression
      # An array of operator symbols.
      OPERATORS = %i[equal greater_than greater_than_equal less_than
                     less_than_equal not_equal and or].freeze

      # The values in the expression, in the order they should be used by the
      # operator.
      attr_reader :vals

      # The operator used in the expression, or nil if it is a standalone
      # expression.
      attr_reader :operator

      # Creates a new CExpression from a +Hash+.
      def self.from_hash(expr_hash)
        op = OPERATORS.find do |op|
          op.to_s == expr_hash[:operator]
        end

        if op.nil?
          msg = "invalid expression operator #{expr_hash[:operator]}"
          raise InvalidSpecKey.new(msg, valid_keys: OPERATORS.map(&:to_s))
        end

        vals = Wrapture.normalize_array(expr_hash[:values])

        CExpression.new(vals, op)
      end

      # An expression as at least one value, and optionally an operator that
      # defines what is done to the values.
      def initialize(vals, operator = nil)
        @vals = case vals
                when String
                  [vals]
                else
                  vals.dup
                end
        @operator = operator
      end
    end
  end
end
