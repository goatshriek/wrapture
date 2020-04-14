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

class EnumSpecTest < Minitest::Test
  def test_basic_enum
    test_spec = load_fixture('basic_enum')

    spec = Wrapture::EnumSpec.new(test_spec)

    assert_equal(test_spec['name'], spec.name)

    generated_files = spec.generate_wrapper
    assert_equal(1, generated_files.count,
                 "only one file should have been generated")

    validate_file_matches_spec(generated_files.first, test_spec)

    File.delete(*generated_files)
  end

  def test_enum_with_namespace
    test_spec = load_fixture('enum_with_namespace')

    spec = Wrapture::EnumSpec.new(test_spec)

    assert_equal(test_spec['name'], spec.name)

    generated_files = spec.generate_wrapper
    assert_equal(1, generated_files.count,
                 "only one file should have been generated")

    validate_file_matches_spec(generated_files.first, test_spec)

    File.delete(*generated_files)
  end

  def test_no_name
    test_spec = load_fixture('invalid/enum_with_no_name')

    error = assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::EnumSpec.new(test_spec)
    end

    %w[name required].each do |keyword|
      assert(error.message.include?(keyword))
    end
  end

  def validate_file_matches_spec(filename, spec_hash)
    enum_name = spec_hash['name']

    expected_filename = "#{enum_name}.hpp"
    assert_equal(expected_filename, filename)

    assert(FileTest.exist?(filename),
           "enum file '#{filename}' was not created")

    if spec_hash.key?('namespace')
      namespace = spec_hash['namespace']
      assert(file_contains_match(filename, namespace),
             "the enum did not reference the namespace '#{namespace}'")
    end

    assert(file_contains_match(filename, enum_name),
           "the enumeration name ('#{enum_name}') was not found in the file")

    spec_hash['elements'].each do |element|
      assert(file_contains_match(filename, element['name']),
             "enumeration did not have element '#{element['name']}'")
    end
  end
end
