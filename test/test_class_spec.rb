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

class ClassSpecTest < Minitest::Test
  def test_invalid_type
    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::ClassSpec.new(load_fixture('invalid_type_class'))
    end
  end

  def test_no_name
    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::ClassSpec.new(load_fixture('no_name_class'))
    end
  end

  def test_normalize
    test_spec = load_fixture('minimal_class')

    normalized_spec = Wrapture::ClassSpec.normalize_spec_hash test_spec

    refute_nil normalized_spec
  end

  def test_future_spec_version
    test_spec = load_fixture('future_version_class')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::ClassSpec.new(test_spec)
    end
  end

  def test_generate_wrappers
    test_spec = load_fixture('basic_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_child_class
    test_spec = load_fixture('child_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_class_with_constructor
    test_spec = load_fixture('constructor_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    source_file = "#{test_spec['name']}.cpp"
    includes = get_include_list(source_file)
    wrapped_function = test_spec['constructors'][0]['wrapped-function']
    assert_includes(includes, wrapped_function['includes'])

    forbidden = Wrapture::EQUIVALENT_STRUCT_KEYWORD
    assert(!file_contains_match(source_file, forbidden))

    class_name = test_spec['name']
    member_regex = /^\s*#{class_name}::#{class_name}\( int member/
    assert(file_contains_match(source_file, member_regex),
           "the member constructor had a return type specified")

    spec_regex = /^\s*#{class_name}::#{class_name}\( struct/
    assert(file_contains_match(source_file, spec_regex),
           "the spec constructor had a return type specified")

    destructor_regex = /^\s#{class_name}::~#{class_name}/
    assert(file_contains_match(source_file, destructor_regex),
           "the destructor had a return type specified")

    assert(file_contains_match(source_file, /= #{wrapped_function['name']}/))

    File.delete(*classes)
  end

  def test_class_with_constant
    test_spec = load_fixture('constant_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_class_with_documentation
    test_spec = load_fixture('documented_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = spec.generate_wrappers
    validate_wrapper_results(test_spec, generated_files)

    File.open('DocumentedClass.hpp').each do |line|
      if line.lstrip.start_with?('/**', '*')
        refute(line.chomp.end_with?(' '))
        assert(line.chomp.length <= 80)
      end
    end

    assert(file_contains_match('DocumentedClass.hpp', '\s\*$'))

    File.delete(*generated_files)
  end

  def test_class_with_no_struct
    test_spec = load_fixture('no_struct_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = spec.generate_wrappers
    validate_wrapper_results(test_spec, generated_files)

    File.delete(*generated_files)
  end

  def test_class_with_static_function
    test_spec = load_fixture('static_function_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    static_function_found = false
    File.open("#{test_spec['name']}.hpp", 'r').each do |line|
      static_function_found = true if line.include? 'static'
    end
    assert static_function_found, 'No static function defined.'

    File.delete(*classes)
  end

  def test_default_constructor_generation
    test_spec = load_fixture('default_value_members')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)
    assert(file_contains_match('DefaultMembersClass.hpp', 'member_1 = 42'))

    File.delete(*classes)
  end

  def test_versioned_class
    test_spec = load_fixture('versioned_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_wrapper_class
    test_spec = load_fixture('struct_wrapper_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end
end
