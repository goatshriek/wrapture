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

# Tests for C++ source formatting.
class CppSourceTest < Minitest::Test
  def test_function_definition_param_of_c_declaration_of_pointer
    base = Wrapture::CSource::CType.new('test_type')
    pointer_type = Wrapture::CSource::CPointer.new(base)
    decl = Wrapture::CSource::CDeclaration.new(pointer_type, 'test_val')
    result = Wrapture::CppSource.format_function_definition_param(decl).join

    assert_equal('test_type *test_val', result)
  end
end
