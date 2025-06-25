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
require 'pathname'
require 'wrapture'

class ClassSpecTest < Minitest::Test
  def test_invalid_type
    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::ClassSpec.new(fixture_hash('invalid_type_class'))
    end
  end

  def test_no_name
    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::ClassSpec.new(fixture_hash('no_name_class'))
    end
  end

  def test_normalize
    test_spec = fixture_hash('minimal_class')

    normalized_spec = Wrapture::ClassSpec.normalize_spec_hash test_spec

    refute_nil normalized_spec
  end

  def test_return_val_in_constructor
    test_spec = fixture_hash('class_with_return_val_in_constructor')

    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)
    validate_cpp_build(spec, build)

    source_name = "#{test_spec['name']}.cpp"

    assert_includes(build, source_name)
    source_file = build[source_name]

    assert(source_file_contains_match?(source_file, 'this->equivalent == NULL'),
           'no error check against the equivalent struct was found')
    refute(source_file_contains_match?(source_file, 'return_val'),
           'a return value variable was still generated')
  end

  def test_future_spec_version
    test_spec = fixture_hash('future_version_class')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::ClassSpec.new(test_spec)
    end
  end

  def test_generate_wrappers
    test_spec = fixture_hash('basic_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)
  end

  def test_child_class
    test_spec = fixture_hash('child_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)
  end

  def test_class_with_constructor
    test_spec = fixture_hash('constructor_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    class_name = test_spec['name']
    header = build["#{class_name}.hpp"]
    member_regex = /^\s*#{class_name}\( int member/
    spec_regex = /^\s*#{class_name}\( struct/
    destructor_regex = /^\s*~#{class_name}/

    assert(source_file_contains_match?(header, member_regex),
           'the member constructor declaration was not found')
    assert(source_file_contains_match?(header, spec_regex),
           'the struct constructor declaration was not found')
    assert(source_file_contains_match?(header, destructor_regex),
           'the destructor declaration was not found')

    source = build["#{class_name}.cpp"]
    includes = get_source_file_include_list(source)

    all_spec_includes(test_spec).each do |inc|
      assert_includes(includes, inc)
    end

    forbidden = Wrapture::EQUIVALENT_STRUCT_KEYWORD

    refute(source_file_contains_match?(source, forbidden),
           'the source file contained a wrapture keyword')

    member_regex = /^\s*#{class_name}::#{class_name}\( int member/
    spec_regex = /^\s*#{class_name}::#{class_name}\( struct/
    destructor_regex = /^\s*#{class_name}::~#{class_name}/

    assert(source_file_contains_match?(source, member_regex),
           'the member constructor definition was not found')
    assert(source_file_contains_match?(source, spec_regex),
           'the spec constructor definition was not found')
    assert(source_file_contains_match?(source, destructor_regex),
           'the destructor definition was not found')

    wrapped_function = test_spec['constructors'][0]['wrapped-function']

    assert(source_file_contains_match?(source, /= #{wrapped_function['name']}/),
           'source file does not include the wrapped function')
  end

  def test_class_with_constant
    test_spec = fixture_hash('constant_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)
  end

  def test_class_with_documentation
    test_spec = fixture_hash('documented_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build['DocumentedClass.hpp']

    source.contents.each do |line|
      if line.lstrip.start_with?('/**', '*')
        refute(line.chomp.end_with?(' '))
        assert_operator(line.chomp.length, :<=, 80)
      end
    end

    assert(source_file_contains_match?(source, '\s\*$'),
           'the end of the comment block was missing')
  end

  def test_class_with_no_struct
    test_spec = fixture_hash('no_struct_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)
  end

  def test_class_with_no_struct_overloads
    test_spec = fixture_hash('no_struct_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    overload_specs = fixture_hash('overloaded_struct')
    parent_spec = Wrapture::ClassSpec.new(overload_specs['classes'].first)

    refute(spec.overloads?(parent_spec))
  end

  def test_class_with_static_function
    test_spec = fixture_hash('static_function_class')
    spec = Wrapture::ClassSpec.new test_spec
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build["#{test_spec['name']}.hpp"]

    assert(source_file_contains_match?(header, 'static'),
           'static keyword not found')
  end

  def test_default_constructor_generation
    test_spec = fixture_hash('default_value_members')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['DefaultMembersClass.hpp']

    assert(source_file_contains_match?(header, 'member_1 = 42'),
           'default value not present in signature')
  end

  def test_delegating_constructor
    test_spec = fixture_hash('delegating_constructor')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build['DelegatingConstructorClass.cpp']
    sig = "#{spec.name}\\( void \\) : #{spec.name}\\( 3 \\)"

    assert(source_file_contains_match?(source, sig),
           'delegating constructor not present')
  end

  def test_versioned_class
    test_spec = fixture_hash('versioned_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)
  end

  def test_wrapper_class
    test_spec = fixture_hash('struct_wrapper_class')
    spec = Wrapture::ClassSpec.new test_spec
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build['StructWrapperClass.cpp']
    member_assignment = 'this->equivalent.member_1 = member_1;'
    pointer_assignment = 'this->equivalent.member_1 = equivalent->member_1;'

    assert(source_file_contains_match?(source, member_assignment),
           'member assignment not present in definition')
    assert(source_file_contains_match?(source, pointer_assignment),
           'pointer member assignment not present in definition')
  end
end
