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

class CmakeBuildTest < Minitest::Test
  def test_cmake_c_build_sources
    build_hash = fixture_hash('cmake_c_build')
    build = Wrapture::Build::CmakeBuild.from_hash(build_hash)
    source_files = build.sources

    source_files.each do |it|
      assert_instance_of(Wrapture::SourceFile, it)
    end

    assert(source_files.one? { |it| it.path.basename.to_s == 'CMakeLists.txt' })
  end

  def test_cmakelists_for_lib
    build_hash = fixture_build_hash('cmake_c_library')
    build = Wrapture::Build::CmakeBuild.from_hash(build_hash)
    cmake_lists = build.cmake_lists

    assert_instance_of(Wrapture::SourceFile, cmake_lists)
    assert(cmake_lists.contents.any? { |it| it.include?('cmakeclib.c') })
    assert(cmake_lists.contents.any? { |it| it.include?('cmakeclib.h') })
  end
end
