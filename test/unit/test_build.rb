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

class BuildTest < Minitest::Test
  def test_cmake_c_build_from_hash
    build_hash = fixture_hash('cmake_c_build')
    build = Wrapture::Build.from_hash(build_hash)

    assert_instance_of(Wrapture::Build::CmakeBuild, build)
    assert_instance_of(Wrapture::Build::CBuild, build.build_info)
  end

  def test_cmake_cpp_build_from_hash
    build_hash = fixture_hash('cmake_cpp_build')
    build = Wrapture::Build.from_hash(build_hash)

    assert_instance_of(Wrapture::Build::CmakeBuild, build)
    assert_instance_of(Wrapture::Build::CppBuild, build.build_info)
  end
end
