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
                     less_than_equal not_equal].freeze

      # An expression as at least one value, and optionally an operator that
      # defines what is done to the values.
      def initialize(vals, operator = nil)
        @vals = @vals = case vals
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
