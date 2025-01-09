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

class SelfReferenceTest < Minitest::Test
  def test_self_reference_function
    test_spec = load_fixture('self_reference_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    forbidden = Wrapture::SELF_REFERENCE_KEYWORD

    build.sources.each do |src|
      refute(source_file_contains_match(src, forbidden),
             "#{src.path} contains wrapture keyword #{forbidden}")
    end

    source = build["#{test_spec['name']}.cpp"]

    assert(source_file_contains_match(source, /return \*this;/))
    refute(source_file_contains_match(source, 'return_val'))
  end
end
