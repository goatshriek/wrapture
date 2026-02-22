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

  def test_delegating_constructor
    test_spec = fixture_hash('alias_constructor')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build['AliasConstructorClass.cpp']
    sig = "#{spec.name}\\(void\\) : #{spec.name}\\(3\\)"

    assert(source_file_contains_match?(source, sig),
           'delegating constructor not present')
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
    signature = /ClassWithConstructor\(const struct constructed_struct \*/

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

  def test_pointer_class_and_child
    test_spec = fixture_hash('pointer_class_and_child')
    spec = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(spec)

    validate_cpp_build(spec, build)

    header = build['ChildPointer.hpp']
    equivalent_signature = 'struct wrapped_struct \*equivalent;'

    refute(source_file_contains_match?(header, equivalent_signature))

    source = build['ChildPointer.cpp']
    parent_initializer = 'equivalent\) : ParentPointer\('

    assert(source_file_contains_match?(source, parent_initializer))
  end

  def test_pointer_class_and_child_with_different_struct
    test_spec = fixture_hash('pointer_class_and_child_with_different_struct')
    spec = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(spec)

    validate_cpp_build(spec, build)

    header = build['ChildPointer.hpp']
    equivalent_signature = 'struct wrapped_struct \*equivalent;'

    refute(source_file_contains_match?(header, equivalent_signature))

    source = build['ChildPointer.cpp']
    parent_initializer = 'equivalent \) : ParentPointer\('

    refute(source_file_contains_match?(source, parent_initializer))
  end

  def test_pointer_class_with_equivalent_pointer_constructor
    spec_name = 'pointer_class_with_equivalent_pointer_constructor'
    test_spec = fixture_hash(spec_name)
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build["#{spec.name}.hpp"]
    constructor_sig = /#{spec.name}\(struct wrapped_struct \*\w+\)/
    num_constructors = count_source_file_matches(source, constructor_sig)

    assert_equal(1, num_constructors)
  end

  def test_pointer_class_with_explicit_pointer_constructor
    test_spec = fixture_hash('pointer_class_with_explicit_pointer_constructor')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build["#{spec.name}.hpp"]
    constructor_sig = /#{spec.name}\(struct wrapped_struct \*\w+\)/
    num_constructors = count_source_file_matches(source, constructor_sig)

    assert_equal(1, num_constructors)
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

  def test_scope_header_with_class_and_enum
    test_spec = fixture_hash('scope_with_enum')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert_includes(build, 'wrapture_test.hpp', 'rollup header missing')

    header = build['wrapture_test.hpp']
    puts header.contents.join

    assert_kind_of(Wrapture::CppSource::CppSourceFile, header)
    assert(source_file_contains_match?(header, 'BasicClass.hpp'))
    assert(source_file_contains_match?(header, 'BasicEnum.hpp'))
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

  def test_sequential_scope_load
    class_specs = [fixture_hash('basic_class'),
                   fixture_hash('child_class'),
                   fixture_hash('constant_class'),
                   fixture_hash('constructor_class')]
    enum_specs = [fixture_hash('basic_enum')]
    scope = Wrapture::Scope.new
    class_specs.each { |spec| scope.add_class_spec_hash(spec) }
    enum_specs.each { |spec| scope.add_enum_spec_hash(spec) }

    assert_equal(class_specs.count, scope.classes.count)
    assert_equal(enum_specs.count, scope.enums.count)

    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    # 2 headers per class, one per enum, and the rollup header
    expected_count = (scope.classes.count * 2) + scope.enums.count + 1

    assert_equal(expected_count, build.sources.count)
  end

  def test_to_language
    assert_equal(:cpp, Wrapture::Wrapper::CToCpp.to_language)
  end
end
