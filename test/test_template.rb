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
  def test_no_param_instantiation
    temp_spec = load_fixture('basic_template')

    temp = Wrapture::TemplateSpec.new(temp_spec)

    assert_equal(temp_spec['value'], temp.instantiate)
  end

  def test_replace_with_no_uses
    temp_spec = load_fixture('basic_template')
    class_spec_original = load_fixture('basic_class')
    class_spec_replaced = load_fixture('basic_class')

    temp = Wrapture::TemplateSpec.new(temp_spec)
    temp.replace_uses(class_spec_replaced)

    assert_equal(class_spec_original, class_spec_replaced)
  end
end