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

class CppWrapperTest < Minitest::Test
  def test_base_decorated_context_namespace_name
    ns = Wrapture::Namespace.new(%w[test namespace])
    ns.source[:base] = { decorate_name: true }
    context = Wrapture::Context.new(ns)
    ns_name = Wrapture::Wrapper::Cpp.context_namespace(context)

    assert_equal('cpp_test_namespace', ns_name)
  end

  def test_base_undecorated_context_namespace_name
    ns = Wrapture::Namespace.new(%w[test namespace])
    ns.source[:base] = { decorate_name: false }
    context = Wrapture::Context.new(ns)
    ns_name = Wrapture::Wrapper::Cpp.context_namespace(context)

    assert_equal('test_namespace', ns_name)
  end

  def test_decorated_namespace_name
    ns = Wrapture::Namespace.new(%w[test namespace])
    ns.source[:cpp] = { decorate_name: true }
    name = Wrapture::Wrapper::Cpp.namespace_name(ns)

    assert_equal('cpp_test_namespace', name)
  end

  def test_default_namespace_name
    ns = Wrapture::Namespace.new(%w[test namespace])
    name = Wrapture::Wrapper::Cpp.namespace_name(ns)

    assert_equal('test_namespace', name)
  end

  def test_nested_context_namesapce
    top_ns = Wrapture::Namespace.new(%w[top namespace])
    top_context = Wrapture::Context.new(top_ns)
    nested_ns = Wrapture::Namespace.new(%w[nested namespace])
    nested_context = Wrapture::Context.new(nested_ns, parent: top_context)
    name = Wrapture::Wrapper::Cpp.context_namespace(nested_context)

    assert_equal('top_namespace::nested_namespace', name)
  end

  def test_standalone_function_namespace_name
    func_spec = Wrapture::FunctionSpec.new(%w[just a func])
    c = Wrapture::Context.new(func_spec)

    assert_empty(Wrapture::Wrapper::Cpp.context_namespace(c))
  end

  def test_top_level_context_namespace
    ns = Wrapture::Namespace.new(%w[test namespace])
    context = Wrapture::Context.new(ns)
    ns_name = Wrapture::Wrapper::Cpp.context_namespace(context)

    assert_equal('test_namespace', ns_name)
  end
end
