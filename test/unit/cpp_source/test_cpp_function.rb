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

class CppFunctionTest < Minitest::Test
  def test_append_nil
    func = Wrapture::CppSource::CppFunction.new('TestAppendNil')
    func << nil

    assert_empty(func.tree)
  end

  def test_new
    func_name = 'NewFunction'
    func = Wrapture::CppSource::CppFunction.new(func_name)

    assert_kind_of(String, func.name)
    assert_equal(func_name, func.name)
    assert_equal(:public, func.accessibility)
    assert_empty(func.tree)
    assert_empty(func.params)
    assert_empty(func.initializers)
    assert_equal('void', func.return_type.to_s)
    refute_predicate(func, :static?)
    refute_predicate(func, :virtual?)
  end
end
