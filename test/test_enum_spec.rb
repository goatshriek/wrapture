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
                 'only one file should have been generated')

    validate_file_matches_spec(generated_files.first, test_spec)

    includes = get_include_list(generated_files.first)
    assert_includes(includes, 'overall_1.h')
    assert_includes(includes, 'overall_2.h')
    assert_includes(includes, 'val_1.h')

    File.delete(*generated_files)
  end

  def test_documentation
    test_spec = load_fixture('documented_enum')

    spec = Wrapture::EnumSpec.new(test_spec)

    generated_files = spec.generate_wrapper

    filename = generated_files.first
    assert(file_contains_match(filename, test_spec['doc']),
           'the doc for the enum was not in the definition')

    test_spec['elements'].each do |elem|
      assert(file_contains_match(filename, elem['doc']),
             "the doc for #{elem['name']} was not in the definition")
    end

    File.delete(*generated_files)
  end

  def test_elements_not_array
    test_spec = load_fixture('invalid/enum_with_non_array_elements')

    error = assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::EnumSpec.new(test_spec)
    end

    %w[elements array].each { |word| assert(error.message.include?(word)) }
  end

  def test_enum_with_namespace
    test_spec = load_fixture('enum_with_namespace')

    spec = Wrapture::EnumSpec.new(test_spec)

    assert_equal(test_spec['name'], spec.name)

    generated_files = spec.generate_wrapper
    assert_equal(1, generated_files.count,
                 'only one file should have been generated')

    validate_file_matches_spec(generated_files.first, test_spec)

    File.delete(*generated_files)
  end

  def test_no_elements
    test_spec = load_fixture('invalid/enum_without_elements')

    error = assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::EnumSpec.new(test_spec)
    end

    %w[elements required].each { |word| assert(error.message.include?(word)) }
  end

  def test_no_name
    test_spec = load_fixture('invalid/enum_without_name')

    error = assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::EnumSpec.new(test_spec)
    end

    %w[name required].each { |word| assert(error.message.include?(word)) }
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
