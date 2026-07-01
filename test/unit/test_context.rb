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
  def test_enum_and_function_in_namespace_name_resolution
    ns_name = %w[test namespace]
    ns = Wrapture::PlainNamespace.new(ns_name)
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
    ns = Wrapture::PlainNamespace.new(ns_name)
    c = Wrapture::Context.new(ns)

    assert_nil(c.resolve_name(nil))
    assert_nil(c.resolve_name([]))
    assert_nil(c.resolve_name(%w[result]))
    assert_nil(c.resolve_name(%w[no result]))

    resolved_ns = c.resolve_name(ns_name)

    refute_nil(resolved_ns)
    assert_same(ns, resolved_ns)
  end

  def test_function_in_parent_name_resolution
    context_ns = Wrapture::PlainNamespace.new(%w[test namespace])
    parent_ns = Wrapture::PlainNamespace.new(%w[parent namespace])
    parent_context = Wrapture::Context.new(parent_ns)
    func_name = %w[test function]
    func = Wrapture::FunctionSpec.new(func_name)
    parent_context.contents << func
    c = Wrapture::Context.new(context_ns, parent: parent_context)
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_func)
    assert_same(func, resolved_func)
  end

  def test_one_word_name_resolution
    ns = Wrapture::PlainNamespace.new(%w[test namespace])
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
    context_ns = Wrapture::PlainNamespace.new(%w[test namespace])
    parent_ns_name = %w[parent namespace]
    parent_ns = Wrapture::PlainNamespace.new(parent_ns_name)
    parent_context = Wrapture::Context.new(parent_ns)
    c = Wrapture::Context.new(context_ns, parent: parent_context)
    resolved_ns = c.resolve_name(parent_ns_name)

    refute_nil(resolved_ns)
    assert_same(parent_ns, resolved_ns)
  end

  def test_single_function_in_namespace_name_resolution
    ns_name = %w[test namespace]
    ns = Wrapture::PlainNamespace.new(ns_name)
    func_name = %w[test function]
    func = Wrapture::FunctionSpec.new(func_name)
    c = Wrapture::Context.new(ns)
    c.contents << func
    resolved_func = c.resolve_name(func_name)

    refute_nil(resolved_func)
    assert_same(func, resolved_func)
  end
end
