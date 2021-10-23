# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019 Joel E. Anderson
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
  def test_class_with_virtual_function
    test_spec = load_fixture('class_with_virtual_function')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    assert(file_contains_match('BaseClass.hpp', 'virtual void'))

    File.delete(*classes)
  end

  def test_virtual_function
    test_spec = load_fixture('virtual_function')

    func_spec = Wrapture::FunctionSpec.new(test_spec)
    assert(func_spec.virtual?)
  end
end
