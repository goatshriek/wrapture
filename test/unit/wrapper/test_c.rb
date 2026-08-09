# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025-2026 Joel E. Anderson
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
    # we need a class spec where there isn't a :c key in source
    class_spec = Wrapture::ClassSpec.new(fixture_hash('versioned_class'))

    assert_empty(Wrapture::Wrapper::C.includes(class_spec),
                 'includes not empty for a class spec with no ' \
                 'entry for c in the source languages')
  end

  def test_class_with_no_struct_overloads
    no_struct_spec = fixture_hash('no_struct_class')
    no_struct_class = Wrapture::ClassSpec.new(no_struct_spec)

    overload_specs = fixture_hash('overloaded_struct')
    parent_spec = Wrapture::ClassSpec.new(overload_specs[:classes].first)

    refute_nil(no_struct_class)
    refute_nil(parent_spec)
    refute(Wrapture::Wrapper::C.overload?(no_struct_class, parent_spec))
    refute(Wrapture::Wrapper::C.overload?(parent_spec, no_struct_class))
  end

  def test_equivalent_ancestor
    ns_spec = fixture_yaml_path('namespace_with_c_equivalent_ancestors')
    context = Wrapture::Context.from_namespace_yaml_file(ns_spec)
    bottom_class = context.resolve_name(%w[bottom class])
    middle_class = context.resolve_name(%w[middle class])
    top_class = context.resolve_name(%w[top class])

    refute_nil(bottom_class)
    refute_nil(middle_class)
    refute_nil(top_class)
    assert(Wrapture::Wrapper::C.equivalent_ancestor?(bottom_class))
    assert(Wrapture::Wrapper::C.equivalent_ancestor?(middle_class))
    refute(Wrapture::Wrapper::C.equivalent_ancestor?(top_class))
  end

  def test_equivalent_member
    ns_spec = fixture_yaml_path('namespace_with_c_equivalent_ancestors')
    context = Wrapture::Context.from_namespace_yaml_file(ns_spec)
    bottom_class = context.resolve_name(%w[bottom class])
    middle_class = context.resolve_name(%w[middle class])
    top_class = context.resolve_name(%w[top class])

    refute_nil(bottom_class)
    refute_nil(middle_class)
    refute_nil(top_class)
    refute(Wrapture::Wrapper::C.equivalent_member?(bottom_class))
    refute(Wrapture::Wrapper::C.equivalent_member?(middle_class))
    assert(Wrapture::Wrapper::C.equivalent_member?(top_class))
  end

  def test_equivalent_member_of_non_context
    ns_spec = fixture_yaml_path('namespace_with_c_equivalent_ancestors')
    context = Wrapture::Context.from_namespace_yaml_file(ns_spec)
    bottom_class = context.resolve_name(%w[bottom class])

    refute(Wrapture::Wrapper::C.equivalent_member?(bottom_class.root))
  end

  def test_factory
    ns_hash = fixture_hash('overloaded_struct')
    context = Wrapture::Context.from_namespace_hash(ns_hash)
    factory_class = context.classes.find do |it|
      it.root.upper_camel_case_name == 'Parent'
    end

    refute_nil(factory_class)
    assert(Wrapture::Wrapper::C.factory?(factory_class))
  end

  def test_function_includes_with_no_c_details
    # we need a function spec where there isn't a :c key in source
    func_spec = Wrapture::FunctionSpec.new(%w[func without c])

    assert_empty(Wrapture::Wrapper::C.includes(func_spec),
                 'includes not empty for a func spec with no ' \
                 'entry for c in the source languages')
  end

  def test_overload
    ns_hash = fixture_hash('overloaded_struct')
    ns = Wrapture::Context.from_namespace_hash(ns_hash)
    factory_context = ns.classes.find do |it|
      it.root.upper_camel_case_name == 'Parent'
    end
    factory_class = factory_context.root
    overload_context_one = ns.classes.find do |it|
      it.root.upper_camel_case_name == 'ChildOne'
    end
    overload_class_one = overload_context_one.root
    overload_context_two = ns.classes.find do |it|
      it.root.upper_camel_case_name == 'ChildTwo'
    end
    overload_class_two = overload_context_two.root

    refute_nil(factory_class)
    refute_nil(overload_class_one)
    refute_nil(overload_class_two)
    assert(Wrapture::Wrapper::C.overload?(factory_class, overload_class_one))
    assert(Wrapture::Wrapper::C.overload?(factory_class, overload_class_two))
  end
end
