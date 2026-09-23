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

class NamespaceTest < Minitest::Test
  def test_from_hash_with_array_source_key
    invalid_hash = { name: 'InvalidNamespace', source: { c: [] } }

    assert_raises(Wrapture::InvalidSpec) do
      Wrapture::Namespace.from_hash(invalid_hash)
    end
  end

  def test_from_hash_with_array_source_value
    invalid_hash = { name: 'InvalidNamespace', source: [] }

    assert_raises(Wrapture::InvalidSpec) do
      Wrapture::Namespace.from_hash(invalid_hash)
    end
  end

  def test_from_hash_with_array_cpp_name
    invalid_hash = { name: 'InvalidNamespace', source: { cpp: { name: [] } } }

    assert_raises(Wrapture::InvalidSpec) do
      Wrapture::Namespace.from_hash(invalid_hash)
    end
  end

  def test_from_hash_with_only_upper_camel_case_name
    ns = Wrapture::Namespace.from_hash({ name: 'MinimalNamespace' })

    assert_kind_of(Wrapture::Namespace, ns)
    assert_equal(%w[minimal namespace], ns.name_words)
  end

  def test_from_hash_without_name
    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::Namespace.from_hash({})
    end
  end

  def test_from_yaml
    ns_file = fixture_yaml_path('minimal_namespace')
    ns = Wrapture::Namespace.from_yaml_file(ns_file)

    assert_kind_of(Array, ns.name_words)
    ns.name_words.each do |it|
      assert_kind_of(String, it)
    end
  end

  def test_name
    ns = Wrapture::Namespace.new(%w[test namespace])

    assert_equal('TestNamespace', ns.upper_camel_case_name)
  end

  def test_versioned_hash
    ns_hash = fixture_hash('versioned_namespace')
    ns = Wrapture::Namespace.from_hash(ns_hash)

    refute_nil(ns)
    assert_equal(%w[wrapture test], ns.name_words)
  end
end
