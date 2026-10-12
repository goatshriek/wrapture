# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2020-2026 Joel E. Anderson
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

class TypeSpecTest < Minitest::Test
  def test_any
    type = Wrapture::TypeSpec.new(Wrapture::TypeSpec::ANY_TYPE_NAME)

    assert_predicate(type, :any?)
  end

  def test_self
    type = Wrapture::TypeSpec.new(Wrapture::TypeSpec::SELF_TYPE_NAME)

    assert_predicate(type, :self?)
  end

  def test_void
    type = Wrapture::TypeSpec.new(Wrapture::TypeSpec::VOID_TYPE_NAME)

    assert_predicate(type, :void?)
  end
end
