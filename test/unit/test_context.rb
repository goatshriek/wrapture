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
  def test_add_unnamed
    context = basic_namespace_context

    assert_raises(Wrapture::InvalidSpec) do
      context << 'this is not named'
    end
  end

  def test_add_context
    context = basic_namespace_context
    added_context = Wrapture::Context.new(Wrapture::Namespace.new(%w[test ns]))

    assert_raises(Wrapture::InvalidSpec) do
      context << added_context
    end
  end

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
    c << func
    c << enum
    resolved_enum = c.resolve_name(enum_name)
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_enum)
    refute_nil(resolved_func)
    assert_same(enum, resolved_enum.root)
    assert_same(func, resolved_func.root)
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
    assert_kind_of(Wrapture::Context, resolved_ns)
    assert_same(ns, resolved_ns.root)
  end

  def test_from_namespace_hash
    hash = fixture_hash('namespace_with_class_and_enum')
    context = Wrapture::Context.from_namespace_hash(hash)

    refute_nil(context)
    assert_kind_of(Wrapture::Namespace, context.root)
    refute_empty(context.classes)
    refute_empty(context.enums)
  end

  def test_from_namespace_hash_with_anchors
    test_spec = fixture_hash('namespace_with_anchors')
    context = Wrapture::Context.from_namespace_hash(test_spec)
    used_structs = %w[one_struct two_struct red_struct blue_struct]

    used_structs.each do |struct_name|
      assert(context.classes.any? do |it|
        it.root[:c].c_type.name == struct_name
      end)
    end
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
    parent_context << func
    c = Wrapture::Context.new(context_ns, parent: parent_context)
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_func)
    assert_kind_of(Wrapture::Context, resolved_func)
    assert_same(func, resolved_func.root)
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

  def test_invalid_parent
    root = Wrapture::Namespace.new(%w[test ns])

    assert_raises(Wrapture::InvalidContext) do
      Wrapture::Context.new(root, parent: 'this is not a context')
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
    c << func
    result = c.resolve_name(func_name)

    refute_nil(result)
    assert_kind_of(Wrapture::Context, result)
    assert_same(func, result.root)
    assert_equal(func_name, result.root.name_words)
  end

  def test_parent_name_resolution
    context_ns = Wrapture::Namespace.new(%w[test namespace])
    parent_ns_name = %w[parent namespace]
    parent_ns = Wrapture::Namespace.new(parent_ns_name)
    parent_context = Wrapture::Context.new(parent_ns)
    c = Wrapture::Context.new(context_ns, parent: parent_context)
    resolved_ns = c.resolve_name(parent_ns_name)

    refute_nil(resolved_ns)
    assert_kind_of(Wrapture::Context, resolved_ns)
    assert_same(parent_ns, resolved_ns.root)
  end

  def test_resolve_nil_name
    context = Wrapture::Context.new(Wrapture::Namespace.new(%w[test ns]))

    assert_nil(context.resolve_name(nil))
  end

  def test_single_function_in_namespace_name_resolution
    ns_name = %w[test namespace]
    ns = Wrapture::Namespace.new(ns_name)
    func_name = %w[test function]
    func = Wrapture::FunctionSpec.new(func_name)
    c = Wrapture::Context.new(ns)
    c << func
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_func)
    assert_kind_of(Wrapture::Context, resolved_func)
    assert_kind_of(Wrapture::FunctionSpec, resolved_func.root)
    assert_same(func, resolved_func.root)
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
