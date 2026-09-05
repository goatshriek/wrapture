# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2026 Joel E. Anderson
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

class VirtualFunctionTest < Minitest::Test
  def test_class_with_virtual_function
    test_spec = fixture_hash('class_with_virtual_function')
    context = Wrapture::Context.from_class_hash(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class_context(context)

    header = build['BaseClass.hpp']

    assert(source_file_contains_match?(header, 'virtual void'),
           'a virtual void function was not found')
  end

  def test_virtual_function
    test_spec = fixture_hash('virtual_function')
    func_spec = Wrapture::FunctionSpec.from_hash(test_spec)

    assert_predicate(func_spec, :virtual?)
  end
end
