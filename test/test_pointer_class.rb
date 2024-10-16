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
  def test_explicit_class
    test_spec = load_fixture('explicit_pointer_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    declaration = 'struct basic_struct \*equivalent;'

    assert(file_contains_match('ExplicitPointerWrapper.hpp', declaration))

    File.delete(*classes)
  end

  # TODO: this should be removed, since it uses c++ specific types in the spec
  # def test_overriding_constructor
  #  test_spec = load_fixture('constructor_class')

  #  spec = Wrapture::ClassSpec.new(test_spec)

  #  classes = Wrapture::CppWrapper.write_spec_source_files(spec)
  #  validate_wrapper_results(test_spec, classes)

  #  count = 0
  #  signature = 'ClassWithConstructor( struct constructed_struct *'
  #  File.open('ClassWithConstructor.hpp').each do |line|
  #    count += 1 if line.include?(signature)
  #  end
  #  assert_equal(1, count)

  #  File.delete(*classes)
  # end

  def test_pointer_class
    test_spec = load_fixture('pointer_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    expected_signature = 'PointerWrappingClass\( struct wrapped_struct \*'

    assert(file_contains_match('PointerWrappingClass.hpp', expected_signature))

    File.delete(*classes)
  end

  def test_pointer_class_and_child
    test_spec = load_fixture('pointer_class_and_child')

    spec = Wrapture::Scope.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    equivalent_signature = 'struct wrapped_struct \*equivalent;'

    refute(file_contains_match('ChildPointer.hpp', equivalent_signature))

    parent_initializer = 'equivalent \) : ParentPointer\('

    assert(file_contains_match('ChildPointer.cpp', parent_initializer))

    File.delete(*classes)
  end

  def test_pointer_class_and_child_with_different_struct
    test_spec = load_fixture('pointer_class_and_child_with_different_struct')

    spec = Wrapture::Scope.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    equivalent_signature = 'struct wrapped_struct \*equivalent;'

    refute(file_contains_match('ChildPointer.hpp', equivalent_signature))

    parent_initializer = 'equivalent \) : ParentPointer\('

    refute(file_contains_match('ChildPointer.cpp', parent_initializer))

    File.delete(*classes)
  end

  def test_pointer_class_with_equivalent_pointer_constructor
    spec_name = 'pointer_class_with_equivalent_pointer_constructor'
    test_spec = load_fixture(spec_name)

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    constructor_sig = /#{spec.name}\( struct wrapped_struct \*\w+ \)/
    num_constructors = count_matches("#{spec.name}.hpp", constructor_sig)

    assert_equal(1, num_constructors)

    File.delete(*classes)
  end

  def test_pointer_class_with_explicit_pointer_constructor
    test_spec = load_fixture('pointer_class_with_explicit_pointer_constructor')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = Wrapture::CppWrapper.write_spec_source_files(spec)
    validate_wrapper_results(test_spec, classes)

    constructor_sig = /#{spec.name}\( struct wrapped_struct \*\w+ \)/
    num_constructors = count_matches("#{spec.name}.hpp", constructor_sig)

    assert_equal(1, num_constructors)

    File.delete(*classes)
  end
end
