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

class SelfReferenceTest < Minitest::Test
  def test_self_reference_function
    test_spec = load_fixture('self_reference_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = Wrapture::CppWrapper.write_files(spec)
    validate_wrapper_results(test_spec, generated_files)

    forbidden = Wrapture::SELF_REFERENCE_KEYWORD
    generated_files.each do |filename|
      refute(file_contains_match(filename, forbidden),
             "#{filename} should not contain '#{forbidden}'")
    end

    source_file = "#{test_spec['name']}.cpp"
    assert(file_contains_match(source_file, /return \*this;/))
    refute(file_contains_match(source_file, 'return_val'))

    File.delete(*generated_files)
  end
end
