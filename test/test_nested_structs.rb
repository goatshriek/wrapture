# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2024 Joel E. Anderson
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
    test_spec = load_fixture('nested_structs')

    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)

    generated_files = Wrapture::CToCppWrapper.write_spec_source_files(scope)
    validate_wrapper_results(test_spec, generated_files)

    includes = get_include_list('Gym.hpp')

    assert_includes(includes, 'Pool.hpp')
    assert_includes(includes, 'Track.hpp')

    includes = get_include_list('Gym.cpp')

    assert_includes(includes, 'Pool.hpp')
    assert_includes(includes, 'Track.hpp')

    File.delete(*generated_files)
  end
end
