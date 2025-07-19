# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2024-2025 Joel E. Anderson
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

class NestedStructsTest < Minitest::Test
  def test_nested_structs
    test_spec = fixture_hash('nested_structs')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert_equal(test_spec[:classes].count, scope.classes.count)

    header_includes = get_source_file_include_list(build['Gym.hpp'])
    source_includes = get_source_file_include_list(build['Gym.cpp'])

    assert_includes(header_includes, 'Pool.hpp')
    assert_includes(header_includes, 'Track.hpp')
    assert_includes(source_includes, 'Pool.hpp')
    assert_includes(source_includes, 'Track.hpp')
  end
end
