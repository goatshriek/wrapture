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

class CStructTest < Minitest::Test
  def test_equals_with_different_members
    name = 'test_struct'
    s1 = Wrapture::CSource::CStruct.new(name: name)
    s1.members << Wrapture::CSource::CType.new('int')
    s2 = Wrapture::CSource::CStruct.new(name: name)

    assert_equal(s1, s2)
    assert_equal(s2, s1)
  end

  def test_includes_from_hash_string_entry
    struct_hash = { name: 'my_struct', includes: 'my_inc.h' }
    struct_instance = Wrapture::CSource::CStruct.from_hash(struct_hash)

    assert_includes(struct_instance.includes, 'my_inc.h')
  end
end
