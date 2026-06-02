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
  def test_filters
    constant_spec = Wrapture::ConstantSpec.new(fixture_hash('basic_constant'))
    class1 = Wrapture::ClassSpec.new(fixture_hash('basic_class'))
    class2 = Wrapture::ClassSpec.new(fixture_hash('child_class'))
    enum_spec = Wrapture::EnumSpec.from_hash(fixture_hash('basic_enum'))
    func_spec = Wrapture::FunctionSpec.new(%w[test function])

    ns = Wrapture::PlainNamespace.new(%w[test namespace])
    ns << constant_spec
    ns << class1
    ns << class2
    ns << enum_spec
    ns << func_spec

    assert_includes(ns.constants, constant_spec)
    refute_includes(ns.constants, class1)
    refute_includes(ns.constants, class2)
    refute_includes(ns.constants, enum_spec)
    refute_includes(ns.constants, func_spec)

    assert_includes(ns.classes, class1)
    assert_includes(ns.classes, class2)
    refute_includes(ns.classes, constant_spec)
    refute_includes(ns.classes, enum_spec)
    refute_includes(ns.classes, func_spec)

    assert_includes(ns.enums, enum_spec)
    refute_includes(ns.enums, class1)
    refute_includes(ns.enums, class2)
    refute_includes(ns.enums, constant_spec)
    refute_includes(ns.enums, func_spec)

    assert_includes(ns.functions, func_spec)
    refute_includes(ns.functions, class1)
    refute_includes(ns.functions, class2)
    refute_includes(ns.functions, constant_spec)
    refute_includes(ns.functions, enum_spec)
  end

  def test_name
    ns = Wrapture::PlainNamespace.new(%w[test namespace])

    assert_equal('TestNamespace', ns.upper_camel_case_name)
  end
end
