# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

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

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

# Tests for C source formatting.
class CSourceTest < Minitest::Test
  def test_not_equals_expression
    expr = Wrapture::CSource::CExpression.new([1, 2], :not_equal)
    code = Wrapture::CSource.format_expression(expr)

    assert_equal('1 != 2', code.join)
  end

  def test_unrecognized_expression_operator
    expr = Wrapture::CSource::CExpression.new([1, 2], :illegal)

    assert_raises(Wrapture::FormatError) do
      Wrapture::CSource.format_expression(expr)
    end
  end
end
