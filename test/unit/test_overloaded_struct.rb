# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2025 Joel E. Anderson
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

class OverloadedStructTest < Minitest::Test
  def test_overloaded_struct
    test_spec = fixture_hash('overloaded_struct')
    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec[:classes].count, scope.classes.count)

    build = Wrapture::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    source = build['Parent.cpp']

    assert(source_file_contains_match?(source, 'newParent'))
    assert(source_file_contains_match?(source, 'Parent \*Parent::newParent'))
    assert(source_file_contains_match?(source,
                                       'Parent \*Parent::OverloadedType'))
    assert(source_file_contains_match?(source, 'return newParent \('))

    includes = get_source_file_include_list(source)

    assert_includes(includes, 'ChildOne.hpp')
    assert_includes(includes, 'ChildTwo.hpp')
  end
end
