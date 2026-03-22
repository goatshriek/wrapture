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

class CWrapperTest < Minitest::Test
  def test_class_includes_with_no_c_details
    # we need a class spec where there isn't a :c key in wrapped
    class_spec = Wrapture::ClassSpec.new(fixture_hash('versioned_class'))

    assert_empty(Wrapture::Wrapper::C.includes(class_spec),
                 'includes not empty for a class spec with no ' \
                 'entry for c in the wrapped languages')
  end

  def test_class_with_no_struct_overloads
    test_spec = fixture_hash('no_struct_class')
    spec = Wrapture::ClassSpec.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_class(spec)

    validate_cpp_build(spec, build)

    overload_specs = fixture_hash('overloaded_struct')
    parent_spec = Wrapture::ClassSpec.new(overload_specs[:classes].first)

    refute(Wrapture::Wrapper::C.overload?(spec, parent_spec))
    refute(Wrapture::Wrapper::C.overload?(parent_spec, spec))
  end

  def test_factory
    scope_hash = fixture_hash('overloaded_struct')
    scope = Wrapture::Scope.new(scope_hash)
    factory_class = scope.classes.find { |it| it.name == 'Parent' }

    assert(Wrapture::Wrapper::C.factory?(factory_class, scope))
  end

  def test_function_includes_with_no_c_details
    # we need a function spec where there isn't a :c key in wrapped
    func_spec = Wrapture::FunctionSpec.new(%w[func without c])

    assert_empty(Wrapture::Wrapper::C.includes(func_spec),
                 'includes not empty for a func spec with no ' \
                 'entry for c in the wrapped languages')
  end

  def test_overload
    scope_hash = fixture_hash('overloaded_struct')
    scope = Wrapture::Scope.new(scope_hash)
    factory_class = scope.classes.find { |it| it.name == 'Parent' }
    overload_class_one = scope.classes.find { |it| it.name == 'ChildOne' }
    overload_class_two = scope.classes.find { |it| it.name == 'ChildTwo' }

    assert(Wrapture::Wrapper::C.overload?(factory_class, overload_class_one))
    assert(Wrapture::Wrapper::C.overload?(factory_class, overload_class_two))
  end
end
