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

class TemplateSpecTest < Minitest::Test
  def test_instantiation
    temp_spec = load_fixture('template_with_params')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    param1 = { 'name' => 'buckle-thing', 'value' => 'shoe' }
    param2 = { 'name' => 'third-thing', 'value' => 'three times a lady' }

    actual_result = temp.instantiate([param1, param2])

    expected_result = temp_spec['value'].dup
    expected_result['key-1'][3] = param1['value']
    expected_result['key-3']['subkey-3'] = param2['value']

    assert_equal(expected_result, actual_result)
  end

  def test_merge_override
    temp_spec = load_fixture('basic_hash_template')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    first_key = temp_spec['value'].keys.first
    override_val = 67
    usage = { first_key => override_val,
              'use-template' => { 'name' => temp_spec['name'] } }

    refute_equal(override_val, temp_spec['value'][first_key])
    temp.replace_uses(usage)

    assert_equal(override_val, usage[first_key])
  end

  def test_multiple_uses
    hash_temp_spec = load_fixture('basic_hash_template')
    array_temp_spec = load_fixture('basic_array_template')

    hash_temp = Wrapture::TemplateSpec.new(hash_temp_spec)
    array_temp = Wrapture::TemplateSpec.new(array_temp_spec)

    usage = load_fixture('multiple_template_uses')

    hash_temp.replace_uses(usage)
    array_temp.replace_uses(usage)

    assert(usage.key?('places'))
    assert(usage.key?('key-1'))
    assert_instance_of(Array, usage['other-stuff'])
    assert(usage['other-stuff'].include?('thing-2'))
  end

  def test_no_param_instantiation
    temp_spec = load_fixture('basic_hash_template')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    assert_equal(temp_spec['value'], temp.instantiate)
  end

  def test_param_replacement
    temp_spec = load_fixture('template_with_params')

    result = Wrapture::TemplateSpec.replace_param(temp_spec['value'],
                                                  'buckle-thing',
                                                  'shoe')

    assert_equal('shoe', result['key-1'][3])
    refute_equal('shoe', temp_spec['value']['key-1'][3])
  end

  def test_replace_in_array
    temp_spec = load_fixture('basic_array_template')
    usage = load_fixture('template_usage_in_array')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    temp.replace_uses(usage)

    puts usage
    assert(usage.include?('thing-1'))
    assert(usage.include?('thing-2'))
    assert(usage.include?('thing-a'))
    assert(usage.include?('thing-b'))
    assert(usage.last.is_a?(Hash))
    assert(usage.last['key-1'] == 'thing-3')
  end

  def test_replace_in_hash
    temp_spec = load_fixture('basic_hash_template')
    usage = load_fixture('template_usage_in_hash')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    temp.replace_uses(usage)

    assert(usage.key?('name'))
    assert(usage.key?('key-1'))
    assert(usage.key?('key-2'))
    assert(usage.key?('key-3'))
    assert(usage['key-3'].is_a?(Array))
  end

  def test_replace_with_no_uses
    temp_spec = load_fixture('basic_hash_template')
    class_spec_original = load_fixture('basic_class')
    class_spec_replaced = load_fixture('basic_class')

    temp = Wrapture::TemplateSpec.new(temp_spec)
    temp.replace_uses(class_spec_replaced)

    assert_equal(class_spec_original, class_spec_replaced)
  end

  def test_shorthand_usage
    temp_spec = load_fixture('basic_hash_template')
    shorthand_usage = load_fixture('template_shorthand_usage')
    verbose_usage = load_fixture('template_usage_in_hash')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    temp.replace_uses(shorthand_usage)
    temp.replace_uses(verbose_usage)

    assert_equal(verbose_usage, shorthand_usage)
  end

  def test_string_template_usage_in_array
    scope_spec = load_fixture('string_template_usage_in_array')

    temp = Wrapture::TemplateSpec.new(scope_spec['templates'].first)

    usage = temp.replace_uses(scope_spec['classes'].first)

    include_list = usage['equivalent-struct']['includes']
    template_value = scope_spec['templates'].first['value']
    assert_includes(include_list, template_value)
  end

  def test_string_template_usage_in_hash
    scope_spec = load_fixture('string_template_usage_in_hash')

    temp = Wrapture::TemplateSpec.new(scope_spec['templates'].first)

    usage = temp.replace_uses(scope_spec['classes'].first)

    assert_equal(scope_spec['templates'].first['value'], usage['namespace'])
  end
end
