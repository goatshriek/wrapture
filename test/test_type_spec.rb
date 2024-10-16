# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2020-2023 Joel E. Anderson
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
  def test_equality_with_int
    refute_equal(Wrapture::TypeSpec.new('const char *'), 3)
  end

  def test_equality_with_string
    type_name = 'const char *'

    assert_equal(Wrapture::TypeSpec.new(type_name), type_name)
  end
end
