# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2026 Joel E. Anderson
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

class ContextTest < Minitest::Test
  def test_classes
    classes = basic_namespace_context.classes

    assert_kind_of(Enumerable, classes)
    assert(1, classes.length)
    classes.each do |it|
      assert_kind_of(Wrapture::Context, it)
      assert_kind_of(Wrapture::ClassSpec, it.root)
    end
  end

  def test_constants
    constants = basic_namespace_context.constants

    assert_kind_of(Enumerable, constants)
    assert(1, constants.length)
    constants.each do |it|
      assert_kind_of(Wrapture::Context, it)
      assert_kind_of(Wrapture::ConstantSpec, it.root)
    end
  end

  def test_enums
    enums = basic_namespace_context.enums

    assert_kind_of(Enumerable, enums)
    assert(1, enums.length)
    enums.each do |it|
      assert_kind_of(Wrapture::Context, it)
      assert_kind_of(Wrapture::EnumSpec, it.root)
    end
  end

  def test_enum_and_function_in_namespace_name_resolution
    ns_name = %w[test namespace]
    ns = Wrapture::Namespace.new(ns_name)
    enum_name = %w[test enum]
    enum = Wrapture::EnumSpec.new(enum_name)
    func_name = %w[test function]
    func = Wrapture::FunctionSpec.new(func_name)
    c = Wrapture::Context.new(ns)
    c.contents << func
    c.contents << enum
    resolved_enum = c.resolve_name(enum_name)
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_enum)
    refute_nil(resolved_func)
    assert_same(enum, resolved_enum)
    assert_same(func, resolved_func)
  end

  def test_empty_name_namespace_name_resolution
    ns_name = %w[test namespace]
    ns = Wrapture::Namespace.new(ns_name)
    c = Wrapture::Context.new(ns)

    assert_nil(c.resolve_name(nil))
    assert_nil(c.resolve_name([]))
    assert_nil(c.resolve_name(%w[result]))
    assert_nil(c.resolve_name(%w[no result]))

    resolved_ns = c.resolve_name(ns_name)

    refute_nil(resolved_ns)
    assert_same(ns, resolved_ns)
  end

  def test_from_namespace_hash
    hash = fixture_hash('namespace_with_class_and_enum')
    context = Wrapture::Context.from_namespace_hash(hash)

    refute_nil(context)
    assert_kind_of(Wrapture::Namespace, context.root)
    assert(context.contents.any?(Wrapture::ClassSpec))
    assert(context.contents.any?(Wrapture::EnumSpec))
  end

  def test_from_namespace_hash_with_class_and_enum
    hash = fixture_hash('namespace_with_class_and_enum')
    c = Wrapture::Context.from_namespace_hash(hash)

    refute_nil(c)
    c.contents.each { |it| assert_kind_of(Wrapture::Context, it) }
    refute_empty(c.classes)
    refute_empty(c.enums)
  end

  def test_function_in_parent_name_resolution
    context_ns = Wrapture::Namespace.new(%w[test namespace])
    parent_ns = Wrapture::Namespace.new(%w[parent namespace])
    parent_context = Wrapture::Context.new(parent_ns)
    func_name = %w[test function]
    func = Wrapture::FunctionSpec.new(func_name)
    parent_context.contents << func
    c = Wrapture::Context.new(context_ns, parent: parent_context)
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_func)
    assert_same(func, resolved_func)
  end

  def test_functions
    functions = basic_namespace_context.functions

    assert_kind_of(Enumerable, functions)
    assert(1, functions.length)
    functions.each do |it|
      assert_kind_of(Wrapture::Context, it)
      assert_kind_of(Wrapture::FunctionSpec, it.root)
    end
  end

  def test_namespaces
    spaces = basic_namespace_context.namespaces

    assert_kind_of(Enumerable, spaces)
    assert(1, spaces.length)
    spaces.each do |it|
      assert_kind_of(Wrapture::Context, it)
      assert_kind_of(Wrapture::Namespace, it.root)
    end
  end

  def test_one_word_name_resolution
    ns = Wrapture::Namespace.new(%w[test namespace])
    c = Wrapture::Context.new(ns)
    func_name = %w[single]
    func = Wrapture::FunctionSpec.new(func_name)
    c.contents << func
    result = c.resolve_name(func_name)

    refute_nil(result)
    assert_kind_of(Wrapture::FunctionSpec, result)
    assert_same(func, result)
    assert_equal(func_name, result.name_words)
  end

  def test_parent_name_resolution
    context_ns = Wrapture::Namespace.new(%w[test namespace])
    parent_ns_name = %w[parent namespace]
    parent_ns = Wrapture::Namespace.new(parent_ns_name)
    parent_context = Wrapture::Context.new(parent_ns)
    c = Wrapture::Context.new(context_ns, parent: parent_context)
    resolved_ns = c.resolve_name(parent_ns_name)

    refute_nil(resolved_ns)
    assert_same(parent_ns, resolved_ns)
  end

  def test_single_function_in_namespace_name_resolution
    ns_name = %w[test namespace]
    ns = Wrapture::Namespace.new(ns_name)
    func_name = %w[test function]
    func = Wrapture::FunctionSpec.new(func_name)
    c = Wrapture::Context.new(ns)
    c.contents << func
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_func)
    assert_same(func, resolved_func)
  end

  def test_top_with_three_levels
    top_ns = Wrapture::Namespace.new(%w[bottom namespace])
    top_c = Wrapture::Context.new(top_ns)
    middle_ns = Wrapture::Namespace.new(%w[middle namespace])
    middle_c = Wrapture::Context.new(middle_ns, parent: top_c)
    bottom_ns = Wrapture::Namespace.new(%w[bottom namespace])
    bottom_c = Wrapture::Context.new(bottom_ns, parent: middle_c)
    top_from_top = top_c.top
    top_from_middle = middle_c.top
    top_from_bottom = bottom_c.top

    refute_nil(top_from_top)
    refute_nil(top_from_middle)
    refute_nil(top_from_bottom)
    assert_same(top_c, top_from_top)
    assert_same(top_c, top_from_middle)
    assert_same(top_c, top_from_bottom)
  end

  def test_top_with_two_levels
    top_ns = Wrapture::Namespace.new(%w[top namespace])
    top_c = Wrapture::Context.new(top_ns)
    bottom_ns = Wrapture::Namespace.new(%w[bottom namespace])
    bottom_c = Wrapture::Context.new(bottom_ns, parent: top_c)
    top_from_top = top_c.top
    top_from_bottom = bottom_c.top

    refute_nil(top_from_top)
    refute_nil(top_from_bottom)
    assert_same(top_c, top_from_top)
    assert_same(top_c, top_from_bottom)
  end

  def test_top_without_parent
    ns = Wrapture::Namespace.new(%w[test namespace])
    c = Wrapture::Context.new(ns)
    top = c.top

    refute_nil(top)
    assert_same(c, top)
  end
end
