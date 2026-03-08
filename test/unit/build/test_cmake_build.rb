# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025-2026 Joel E. Anderson
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
  def test_cmake_c_build_save
    set = Wrapture::CSource::CSourceSet.new('c_source_save_test')
    src = Wrapture::CSource::CSourceFile.new('src.c')
    src_comment = '// this is a test source file for saving c source sets'
    src << src_comment
    set.add_lib_source(src)
    header = Wrapture::CSource::CSourceFile.new('src.h')
    header_comment = '// this is a test header file for saving c source sets'
    header << header_comment
    set.add_lib_header(header)
    build = Wrapture::Build::CmakeBuild.new(set)

    Dir.mktmpdir do |dir|
      base_path = Pathname.new(dir)
      build.save(dir)
      src_path = base_path.join('src', 'src.c')
      header_path = base_path.join('include', 'src.h')

      assert_path_exists(base_path.join('CMakeLists.txt'))
      assert_path_exists(src_path)
      assert_path_exists(header_path)

      header_contents = File.read(header_path)
      src_contents = File.read(src_path)

      assert_equal(src_comment, src_contents)
      assert_equal(header_comment, header_contents)
    end
  end

  def test_cmake_c_build_save_include_dir_exists
    set = Wrapture::CSource::CSourceSet.new('c_source_save_include_exists_test')
    header = Wrapture::CSource::CSourceFile.new('src.h')
    header_comment = '// this is a test header file for saving c source sets'
    header << header_comment
    set.add_lib_header(header)
    build = Wrapture::Build::CmakeBuild.new(set)

    Dir.mktmpdir do |dir|
      base_path = Pathname.new(dir)
      Dir.mkdir(base_path.join('include'))
      build.save(dir)
      header_path = base_path.join('include', 'src.h')

      assert_path_exists(base_path.join('CMakeLists.txt'))
      assert_path_exists(header_path)

      header_contents = File.read(header_path)

      assert_equal(header_comment, header_contents)
    end
  end

  def test_cmake_c_build_sources
    build_hash = fixture_hash('cmake_c_sources')
    build = Wrapture::Build::CmakeBuild.from_hash(build_hash)
    source_files = build.sources

    source_files.each do |it|
      assert_kind_of(Wrapture::SourceFile, it)
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

  def test_cmakelists_for_export_header
    export = Wrapture::CSource::CExportHeader.new('test_export.h',
                                                  'TEST_BASE_NAME')
    source_set = Wrapture::CSource::CSourceSet.new('test_export_lib')
    source_set.add_lib_header(export)
    build = Wrapture::Build::CmakeBuild.new(source_set)
    cmake_lists = build.cmake_lists

    assert_instance_of(Wrapture::SourceFile, cmake_lists)
    assert(source_file_contains_match?(cmake_lists,
                                       'include\(GenerateExportHeader\)'))
    assert(source_file_contains_match?(cmake_lists,
                                       'BASE_NAME "TEST_BASE_NAME"'))
  end
end
