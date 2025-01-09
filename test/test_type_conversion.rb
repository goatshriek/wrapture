# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2020-2025 Joel E. Anderson
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

class TypeConversionTest < Minitest::Test
  def test_class_pointer_to_struct_pointer
    test_spec = load_fixture('scope_with_pointer_param')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert(source_file_contains_match(build['Rifle.cpp'], /bullet->equivalent/),
           'equivalent struct member was not referenced')
  end

  def test_reference_to_pointer
    test_spec = load_fixture('scope_with_reference_param')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert(source_file_contains_match(build['Rifle.cpp'], /bullet\.equivalent/),
           'equivalent struct member was not referenced')
  end
end
