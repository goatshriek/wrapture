# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2020 Joel E. Anderson
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

class ActionSpecTest < Minitest::Test
  def test_basic
    test_spec = load_fixture('basic_action')

    spec = Wrapture::ActionSpec.new(test_spec)

    common_includes = spec.includes & test_spec['constructor']['includes']
    assert_equal(common_includes, test_spec['constructor']['includes'])

    action = spec.take

    assert(action.include?('throw NewCustomException'))
  end

  def test_exception_without_params
    test_spec = load_fixture('exception_action_without_params')

    spec = Wrapture::ActionSpec.new(test_spec)

    assert_match(/#{test_spec['constructor']['name']}\(\s*\)/, spec.take)
  end

  def test_extra_key
    test_spec = load_fixture('extra_key_action')

    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::ActionSpec.new(test_spec)
    end
  end

  def test_missing_key
    test_spec = load_fixture('missing_key_action')

    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::ActionSpec.new(test_spec)
    end
  end
end
