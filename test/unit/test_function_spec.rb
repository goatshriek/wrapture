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

class FunctionSpecTest < Minitest::Test
  def test_future_spec_version
    test_spec = fixture_hash('future_version_function')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::FunctionSpec.from_hash(test_spec)
    end
  end

  def test_from_hash_with_implicit_void_return
    spec_hash = fixture_hash('function_with_implicit_void_return')
    func_spec = Wrapture::FunctionSpec.from_hash(spec_hash)

    assert_kind_of(Wrapture::TypeSpec, func_spec.return_type)
    assert_equal('void', func_spec.return_type.base)
  end

  def test_from_hash_with_initializers
    spec_hash = fixture_hash('function_with_initializers')
    func_spec = Wrapture::FunctionSpec.from_hash(spec_hash)

    assert_kind_of(Array, func_spec.initializers)
    assert_equal(spec_hash[:initializers], func_spec.initializers)
  end

  def test_only_variadic_param
    test_spec = fixture_hash('invalid/only_variadic_param')

    error = assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::FunctionSpec.from_hash(test_spec)
    end

    assert_includes(error.message, 'only param')
  end

  def test_versioned_function
    test_spec = fixture_hash('versioned_function')
    Wrapture::FunctionSpec.from_hash(test_spec)
  end
end
