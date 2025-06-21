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

class ClassSpecTest < Minitest::Test
  def test_explicit_class
    test_spec = load_fixture('explicit_pointer_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['ExplicitPointerWrapper.hpp']
    declaration = 'struct basic_struct \*equivalent;'

    assert(source_file_contains_match?(header, declaration))
  end

  # TODO: this should be reworked, since it uses c++ specific types in the spec
  def test_overriding_constructor
    test_spec = load_fixture('constructor_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['ClassWithConstructor.hpp']
    signature = /ClassWithConstructor\( struct constructed_struct \*/

    assert_equal(1, count_source_file_matches(header, signature))
  end

  def test_pointer_class
    test_spec = load_fixture('pointer_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    header = build['PointerWrappingClass.hpp']
    expected_signature = 'PointerWrappingClass\( struct wrapped_struct \*'

    assert(source_file_contains_match?(header, expected_signature))
  end

  def test_pointer_class_and_child
    test_spec = load_fixture('pointer_class_and_child')
    spec = Wrapture::Scope.new(test_spec)
    build = Wrapture::CToCpp.wrap_scope(spec)

    validate_cpp_build(spec, build)

    header = build['ChildPointer.hpp']
    equivalent_signature = 'struct wrapped_struct \*equivalent;'

    refute(source_file_contains_match?(header, equivalent_signature))

    source = build['ChildPointer.cpp']
    parent_initializer = 'equivalent \) : ParentPointer\('

    assert(source_file_contains_match?(source, parent_initializer))
  end

  def test_pointer_class_and_child_with_different_struct
    test_spec = load_fixture('pointer_class_and_child_with_different_struct')
    spec = Wrapture::Scope.new(test_spec)
    build = Wrapture::CToCpp.wrap_scope(spec)

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
    test_spec = load_fixture(spec_name)
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build["#{spec.name}.hpp"]
    constructor_sig = /#{spec.name}\( struct wrapped_struct \*\w+ \)/
    num_constructors = count_source_file_matches(source, constructor_sig)

    assert_equal(1, num_constructors)
  end

  def test_pointer_class_with_explicit_pointer_constructor
    test_spec = load_fixture('pointer_class_with_explicit_pointer_constructor')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    source = build["#{spec.name}.hpp"]
    constructor_sig = /#{spec.name}\( struct wrapped_struct \*\w+ \)/
    num_constructors = count_source_file_matches(source, constructor_sig)

    assert_equal(1, num_constructors)
  end
end
