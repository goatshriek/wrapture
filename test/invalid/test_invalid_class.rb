# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2021 Joel E. Anderson
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

class InvalidClassTest < Minitest::Test
  def test_initializer_missing_name
    test_spec = load_fixture('invalid/initializer_missing_name')

    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::ClassSpec.new(test_spec)
    end
  end
end
