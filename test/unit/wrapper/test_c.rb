# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025 Joel E. Anderson
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

class CWrapperTest < Minitest::Test
  def test_class_includes_with_no_c_details
    # we need a class spec where there isn't a :c key in wrapped
    class_spec = Wrapture::ClassSpec.new(fixture_hash('versioned_class'))

    assert_empty(Wrapture::Wrapper::C.includes(class_spec),
                 'includes not empty for a class spec with no ' \
                 'entry for c in the wrapped languages')
  end

  def test_function_includes_with_no_c_details
    # we need a function spec where there isn't a :c key in wrapped
    func_spec = Wrapture::FunctionSpec.new(%w[func without c])

    assert_empty(Wrapture::Wrapper::C.includes(func_spec),
                 'includes not empty for a func spec with no ' \
                 'entry for c in the wrapped languages')
  end
end
