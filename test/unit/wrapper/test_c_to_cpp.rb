# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025 Joel E. Anderson
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

class CToCppTest < Minitest::Test
  def test_basic_enum
    test_spec = fixture_hash('basic_enum')
    spec = Wrapture::EnumSpec.from_hash(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_enum(spec)

    validate_cpp_build(spec, build)

    assert_equal(test_spec[:name], spec.name)
    assert_equal(1, build.sources.count,
                 'only one file should have been generated')

    validate_cpp_source_file_matches_enum_spec(build.sources.first, test_spec)

    includes = get_source_file_include_list(build.sources.first)

    assert_includes(includes, 'overall_1.h')
    assert_includes(includes, 'overall_2.h')
    assert_includes(includes, 'val_1.h')
  end

  def test_class_pointer_to_struct_pointer
    test_spec = fixture_hash('scope_with_pointer_param')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert(source_file_contains_match?(build['Rifle.cpp'],
                                       /bullet->equivalent/),
           'equivalent struct member was not referenced')
  end

  def test_declaration_includes_with_no_c_details
    # we need a class spec where there isn't a :c key in wrapped
    class_spec = Wrapture::ClassSpec.new(fixture_hash('versioned_class'))

    assert_empty(Wrapture::Wrapper::CToCpp.declaration_includes(class_spec),
                 'declaration includes not empty for a class spec with no ' \
                 'entry for c in the wrapped languages')
  end

  def test_enum_with_namespace
    test_spec = fixture_hash('enum_with_namespace')
    spec = Wrapture::EnumSpec.from_hash(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_enum(spec)

    assert_equal(test_spec[:name], spec.name)
    assert_equal(1, build.sources.count,
                 'only one file should have been generated')

    validate_cpp_source_file_matches_enum_spec(build.sources.first, test_spec)
  end

  def test_explicit_class
    test_spec = fixture_hash('explicit_pointer_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['ExplicitPointerWrapper.hpp']
    declaration = 'struct basic_struct \*equivalent;'

    assert(source_file_contains_match?(header, declaration))
  end

  def test_from_language
    assert_equal(:c, Wrapture::Wrapper::CToCpp.from_language)
  end

  def test_overloaded_struct
    test_spec = fixture_hash('overloaded_struct')
    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec[:classes].count, scope.classes.count)

    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    source = build['Parent.cpp']

    assert(source_file_contains_match?(source, 'NewParent'))
    assert(source_file_contains_match?(source, 'Parent \*Parent::NewParent'))
    assert(source_file_contains_match?(source,
                                       'Parent \*Parent::OverloadedType'))
    assert(source_file_contains_match?(source, 'return NewParent\('))

    includes = get_source_file_include_list(source)

    assert_includes(includes, 'ChildOne.hpp')
    assert_includes(includes, 'ChildTwo.hpp')
  end

  def test_overriding_constructor
    test_spec = fixture_hash('constructor_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['ClassWithConstructor.hpp']
    signature = /ClassWithConstructor\(struct constructed_struct \*/

    assert_equal(1, count_source_file_matches(header, signature))
  end

  def test_pointer_class
    test_spec = fixture_hash('pointer_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['PointerWrappingClass.hpp']
    expected_signature = 'PointerWrappingClass\(struct wrapped_struct \*'

    assert(source_file_contains_match?(header, expected_signature))
  end

  def test_reference_to_pointer
    test_spec = fixture_hash('scope_with_reference_param')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert(source_file_contains_match?(build['Rifle.cpp'],
                                       /bullet\.equivalent/),
           'equivalent struct member was not referenced')
  end

  def test_self_reference_function
    test_spec = fixture_hash('self_reference_class')
    spec = Wrapture::ClassSpec.from_hash(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    forbidden = Wrapture::SELF_REFERENCE_KEYWORD

    build.sources.each do |src|
      refute(source_file_contains_match?(src, forbidden),
             "#{src.path} contains wrapture keyword #{forbidden}")
    end

    source = build["#{test_spec[:name]}.cpp"]

    assert(source_file_contains_match?(source, /return \*this;/))
    refute(source_file_contains_match?(source, 'return_val'))
  end

  def test_to_language
    assert_equal(:cpp, Wrapture::Wrapper::CToCpp.to_language)
  end
end
