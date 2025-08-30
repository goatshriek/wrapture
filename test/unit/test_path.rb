# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2025 Joel E. Anderson
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

require 'minitest/autorun'
require 'wrapture'

class PathTest < Minitest::Test
  def test_path_from_array
    wrapper_array = [Wrapture::Wrapper::CToCpp]
    path = Wrapture::Path.new(wrapper_array)

    assert_equal(wrapper_array, path.wrappers)
  end

  def test_path_from_string
    path = Wrapture::Path.new('c,cpp')

    assert_equal([Wrapture::Wrapper::CToCpp], path.wrappers)
  end

  def test_wrappers_from_string
    wrappers = Wrapture::Path.wrappers_from_string('c,cpp')

    assert_equal([Wrapture::Wrapper::CToCpp], wrappers)
  end
end
