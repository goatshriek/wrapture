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

class PythonWrapperTest < Minitest::Test
  # TODO: pick up here, converting to module tests
  def test_decorated_module_name
    ns = Wrapture::Namespace.new(%w[test namespace])
    ns.source[:python] = { decorate_name: true }
    name = Wrapture::Wrapper::Python.module_name(ns)

    assert_equal('py_test_namespace', name)
  end

  def test_default_module_name
    ns = Wrapture::Namespace.new(%w[test namespace])
    name = Wrapture::Wrapper::Python.module_name(ns)

    assert_equal('test_namespace', name)
  end
end
