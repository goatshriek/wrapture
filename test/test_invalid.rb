# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2020 Joel E. Anderson
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

class InvalidTest < Minitest::Test
  def test_class_with_invalid_doc
    test_spec = load_fixture('invalid/class_with_invalid_doc')

    assert_raises(Wrapture::InvalidDoc) do
      Wrapture::ClassSpec.new(test_spec)
    end
  end

  def test_invalid_virtual_key
    test_spec = load_fixture('invalid/invalid_virtual_key')

    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::FunctionSpec.new(test_spec)
    end
  end

  def test_no_namespace
    test_spec = load_fixture 'invalid/no_namespace'

    assert_raises(Wrapture::WraptureError) do
      Wrapture::ClassSpec.new test_spec
    end
  end

  def test_non_hash_template_in_hash
    scope_spec = load_fixture('invalid/non_hash_template_in_hash')

    assert_raises(Wrapture::InvalidTemplateUsage) do
      Wrapture::Scope.new(scope_spec)
    end
  end

  def test_rule_missing_condition
    test_spec = load_fixture('invalid/rule_missing_condition')

    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_rule_with_invalid_condition
    test_spec = load_fixture('invalid/rule_with_invalid_condition')

    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_rule_with_invalid_key
    test_spec = load_fixture('invalid/rule_with_invalid_key')

    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_use_template_as_array
    scope_spec = load_fixture('invalid/use_template_as_array')

    error = assert_raises(Wrapture::InvalidTemplateUsage) do
      Wrapture::Scope.new(scope_spec)
    end

    assert(error.message.include?(Wrapture::TEMPLATE_USE_KEYWORD))
  end

  def test_use_template_with_no_name
    scope_spec = load_fixture('invalid/use_template_with_no_name')

    assert_raises(Wrapture::InvalidTemplateUsage) do
      Wrapture::Scope.new(scope_spec)
    end
  end
end
