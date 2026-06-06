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

class PlainNamespaceTest < Minitest::Test
  def test_append
    ns = Wrapture::PlainNamespace.new(%w[test namespace])
    class_spec = Wrapture::ClassSpec.new(fixture_hash('basic_class'))
    result = ns << class_spec

    assert_equal(ns, result)
    assert_includes(ns.classes, class_spec)
  end

  def test_classes
    classes = basic_namespace.classes

    assert(1, classes.length)
    classes.each { |it| assert_kind_of(Wrapture::ClassSpec, it) }
  end

  def test_constants
    constants = basic_namespace.constants

    assert(1, constants.length)
    constants.each { |it| assert_kind_of(Wrapture::ConstantSpec, it) }
  end

  def test_enums
    enums = basic_namespace.enums

    assert(1, enums.length)
    enums.each { |it| assert_kind_of(Wrapture::EnumSpec, it) }
  end

  def test_functions
    functions = basic_namespace.functions

    assert(1, functions.length)
    functions.each { |it| assert_kind_of(Wrapture::FunctionSpec, it) }
  end

  def test_name
    ns = Wrapture::PlainNamespace.new(%w[test namespace])

    assert_equal('TestNamespace', ns.upper_camel_case_name)
  end
end
