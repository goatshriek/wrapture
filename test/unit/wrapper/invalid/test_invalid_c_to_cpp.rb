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

class InvalidCToCppTest < Minitest::Test
  # If the return type of a constructor doesn't match the type used in the
  # class, then an exception is raised.
  def test_constructor_return_type_mismatch
    hash = fixture_hash('invalid/class_with_c_constructor_return_type_mismatch')
    spec = Wrapture::ClassSpec.from_hash(hash)

    assert_raises(Wrapture::InvalidConstructor) do
      Wrapture::Wrapper::CToCpp.wrap_class(spec)
    end
  end

  # If the return type doesn't exist for a constructor, an exception is raised.
  def test_no_constructor_return_type
    hash = fixture_hash('invalid/class_with_no_return_type_in_c_constructor')

    assert_raises(Wrapture::InvalidConstructor) do
      Wrapture::ClassSpec.from_hash(hash)
    end
  end
end
