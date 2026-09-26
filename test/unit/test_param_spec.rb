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

class ParamSpecTest < Minitest::Test
  def test_from_hash_default_value
    default_value = 'default_value'
    param_hash = {
      name: %w[param with default value],
      type: 'something',
      default_value: default_value
    }
    param_spec = Wrapture::ParamSpec.from_hash(param_hash)

    refute_nil(param_spec)
    assert_equal(default_value, param_spec.default_value)
  end

  def test_from_hash_missing_name
    error = assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::ParamSpec.from_hash({ type: 'void' })
    end

    assert_includes(error.message, ':name')
  end

  def test_from_hash_missing_type
    error = assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::ParamSpec.from_hash({ name: %w[no type here] })
    end

    assert_includes(error.message, ':type')
  end

  def test_variadic_parameter
    Wrapture::ParamSpec.new(%w[variadic param], '...')
  end
end
