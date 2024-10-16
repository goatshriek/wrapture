# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2021 Joel E. Anderson
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

  def test_return_val_in_constructor
    test_spec = load_fixture('class_with_return_val_in_constructor')

    spec = Wrapture::ClassSpec.new(test_spec)
    generated_files = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, generated_files)

    source_file = "#{test_spec['name']}.cpp"

    assert(file_contains_match(source_file, 'this->equivalent == NULL'),
           'no error check against the equivalent struct was found')
    refute(file_contains_match(source_file, 'return_val'),
           'a return value variable was still generated')

    File.delete(*generated_files)
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

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_child_class
    test_spec = load_fixture('child_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_class_with_constructor
    test_spec = load_fixture('constructor_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, generated_files)

    class_name = test_spec['name']
    header_file = "#{class_name}.hpp"

    member_regex = /^\s*#{class_name}\( int member/

    assert(file_contains_match(header_file, member_regex),
           'the member constructor had a return type specified in the header')

    spec_regex = /^\s*#{class_name}\( struct/

    assert(file_contains_match(header_file, spec_regex),
           'the spec constructor had a return type specified in the header')

    destructor_regex = /^\s*~#{class_name}/

    assert(file_contains_match(header_file, destructor_regex),
           'the destructor had a return type specified in the header')

    source_file = "#{class_name}.cpp"
    includes = get_include_list(source_file)

    all_spec_includes(test_spec).each do |inc|
      assert_includes(includes, inc)
    end

    forbidden = Wrapture::EQUIVALENT_STRUCT_KEYWORD

    refute(file_contains_match(source_file, forbidden))

    member_regex = /^\s*#{class_name}::#{class_name}\( int member/

    assert(file_contains_match(source_file, member_regex),
           'the member constructor had a return type specified when defined')

    spec_regex = /^\s*#{class_name}::#{class_name}\( struct/

    assert(file_contains_match(source_file, spec_regex),
           'the spec constructor had a return type specified when defined')

    destructor_regex = /^\s*#{class_name}::~#{class_name}/

    assert(file_contains_match(source_file, destructor_regex),
           'the destructor was not defined properly')

    wrapped_function = test_spec['constructors'][0]['wrapped-function']

    assert(file_contains_match(source_file, /= #{wrapped_function['name']}/))

    File.delete(*generated_files)
  end

  def test_class_with_constant
    test_spec = load_fixture('constant_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_class_with_documentation
    test_spec = load_fixture('documented_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, generated_files)

    File.open('DocumentedClass.hpp').each do |line|
      if line.lstrip.start_with?('/**', '*')
        refute(line.chomp.end_with?(' '))
        assert_operator(line.chomp.length, :<=, 80)
      end
    end

    assert(file_contains_match('DocumentedClass.hpp', '\s\*$'))

    File.delete(*generated_files)
  end

  def test_class_with_no_struct
    test_spec = load_fixture('no_struct_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, generated_files)

    File.delete(*generated_files)
  end

  def test_class_with_no_struct_overloads
    test_spec = load_fixture('no_struct_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    generated_files = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, generated_files)

    overload_specs = load_fixture('overloaded_struct')
    parent_spec = Wrapture::ClassSpec.new(overload_specs['classes'].first)
    spec.overloads?(parent_spec)

    File.delete(*generated_files)
  end

  def test_class_with_static_function
    test_spec = load_fixture('static_function_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
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

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    assert(file_contains_match('DefaultMembersClass.hpp', 'member_1 = 42'),
           'default value not present in signature')

    File.delete(*classes)
  end

  def test_delegating_constructor
    test_spec = load_fixture('delegating_constructor')
    spec = Wrapture::ClassSpec.new(test_spec)
    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    sig = "#{spec.name}\\( void \\) : #{spec.name}\\( 3 \\)"

    assert(file_contains_match('DelegatingConstructorClass.cpp', sig),
           'delegating constructor not present')

    File.delete(*classes)
  end

  def test_versioned_class
    test_spec = load_fixture('versioned_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_wrapper_class
    test_spec = load_fixture('struct_wrapper_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    filename = 'StructWrapperClass.cpp'
    assignment = 'this->equivalent.member_1 = member_1;'
    failure_msg = 'member assignment not present in definition'

    assert(file_contains_match(filename, assignment), failure_msg)

    assignment = 'this->equivalent.member_1 = equivalent->member_1;'
    failure_msg = 'pointer member assignment not present in definition'

    assert(file_contains_match(filename, assignment), failure_msg)

    File.delete(*classes)
  end
end
