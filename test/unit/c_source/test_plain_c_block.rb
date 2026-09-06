# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025-2026 Joel E. Anderson
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

class PlainCBlockTest < Minitest::Test
  def test_concat_single_array
    blk = Wrapture::CSource::PlainCBlock.new
    blk.concat(['int a;', 'int b;', 'int c;'])

    refute_empty(blk.tree)
    assert_includes(blk.tree, 'int a;')
    assert_includes(blk.tree, 'int b;')
    assert_includes(blk.tree, 'int c;')
  end

  def test_concat_two_arrays
    blk = Wrapture::CSource::PlainCBlock.new
    blk.concat(['int a;', 'int b;', 'int c;'], ['char x;', 'char y;'])

    refute_empty(blk.tree)
    assert_includes(blk.tree, 'int a;')
    assert_includes(blk.tree, 'int b;')
    assert_includes(blk.tree, 'int c;')
    assert_includes(blk.tree, 'int a;')
    assert_includes(blk.tree, 'char x;')
    assert_includes(blk.tree, 'char y;')
  end

  def test_declaration
    blk = Wrapture::CSource::PlainCBlock.new
    blk.declare('int', 'variable_name')
    fmt = Wrapture::CSource.format_block(blk.tree).join

    assert_includes(fmt, 'int variable_name;')
  end
end
