# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
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
#++

require 'wrapture/source_set'

module Wrapture
  module Build
    # A CMake project that builds a library.
    #
    # CMake is a common build system for C and C++ projects. It uses a file
    # named CMakeLists.txt to describe how to build a project, including
    # information about the source files and any dependencies required.
    class CmakeBuild
      include Build
      include SourceSet

      # The root path for include files.
      attr_accessor :include_dir

      # The underlying sources for the project.
      attr_reader :source_set

      # The root path for source files.
      attr_accessor :source_dir

      # Creates a CMake build from a provided hash.
      def self.from_hash(spec)
        unless spec.key?(:c_sources) || spec.key?(:cpp_sources)
          raise(MissingSpecKey,
                'an underlying c or c++ source set must be specified')
        end

        build_info = if spec.key?(:c_sources)
                       CSource::CSourceSet.from_hash(spec[:c_sources])
                     else
                       CppSource::CppSourceSet.from_hash(spec[:cpp_sources])
                     end

        new(build_info)
      end

      # Create a CMake build for a set of source files.
      def initialize(source_set)
        @source_set = source_set
        @include_dir = '${PROJECT_SOURCE_DIR}/include/'
        @source_dir = '${PROJECT_SOURCE_DIR}/src/'
      end

      # Invocations of CMake to configure and build this project.
      def build_commands
        ['cmake .', "cmake --build . --target #{@source_set.name}"]
      end

      # The sources for the CMake build system.
      def build_sources
        [cmake_lists]
      end

      # A CMakeLists.txt file that could be used to build this project.
      def cmake_lists
        # TODO: pick up here, add definition of export macro to target build

        file = SourceFile.new('CMakeLists.txt')
        file.puts('cmake_minimum_required(VERSION 3.10)')
        file.puts("project(#{@source_set.name})")
        file.puts
        file.puts("set(#{include_dir_variable}")
        file.puts("  \"#{@include_dir}\"")
        file.puts(')')
        file.puts
        file.puts("set(#{@source_set.name.upcase}_SOURCE_DIR")
        file.puts("  \"#{@source_dir}\"")
        file.puts(')')
        file.puts

        src_path_prefix = "${#{@source_set.name.upcase}_SOURCE_DIR}/"
        exports = @source_set.lib_headers.grep(CSource::CExportHeader)

        unless @source_set.lib_sources.empty?
          source_list = "#{@source_set.name.upcase}_SOURCES"
          file.puts("set(#{source_list}")
          @source_set.lib_sources.each do |source|
            file.puts("  \"#{src_path_prefix}#{source.path}\"")
          end
          file.puts(')')
          file.puts

          lib_targets = []
          @source_set.lib_links.each do |lib|
            target_name = "#{@source_set.name}_#{lib}"
            find_var = "LIB#{lib.upcase}_LOCATION"
            file.puts("find_library(#{find_var} #{lib} REQUIRED)")
            file.puts("add_library(#{target_name} SHARED IMPORTED)")
            file.puts("set_target_properties(#{target_name} PROPERTIES")
            file.puts("  IMPORTED_LOCATION ${#{find_var}}")
            file.puts(')')
            file.puts

            lib_targets.append(target_name)
          end

          lib_deps = lib_targets.join(' ')
          file.puts("add_library(#{@source_set.name} ${#{source_list}})")
          file.puts("target_link_libraries(#{@source_set.name}")
          file.puts("  PUBLIC #{lib_deps}")
          file.puts(')')
          file.puts("target_include_directories(#{@source_set.name}")
          target_include_directories.each do |dir|
            file.puts("  PRIVATE \"#{dir}\"")
          end
          file.puts(')')

          unless exports.empty?
            file.puts("target_compile_definitions(#{@source_set.name}")
            exports.each do |export|
              file.puts("  PRIVATE #{export.base_name}_EXPORTING=1")
            end
            file.puts(')')
          end

          file.puts
        end

        unless exports.empty?
          file.puts('include(GenerateExportHeader)')
          exports.each do |export|
            export_path = "${PROJECT_BINARY_DIR}/include/#{export.path}"
            file.puts("generate_export_header(#{@source_set.name}")
            file.puts("  BASE_NAME \"#{export.base_name}\"")
            file.puts("  EXPORT_FILE_NAME \"#{export_path}\"")
            file.puts(')')
          end
        end

        header_list = "#{@source_set.name.upcase}_HEADERS"
        file.puts("set(#{header_list}")
        target_headers.each do |header|
          file.puts("  \"#{header}\"")
        end
        file.puts(')')
        file.puts

        file.puts('include(GNUInstallDirs)')
        file.puts("install(TARGETS #{@source_set.name})")
        header_dest = 'DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"'
        file.puts("install(FILES ${#{header_list}} #{header_dest})")

        file
      end

      # The CMake variable that holds the include directory for the project.
      def include_dir_variable
        "#{@source_set.name.upcase}_INCLUDE_DIR"
      end

      # Invocations of CMake to configure and install this project.
      def install_commands(install_dir: '.')
        ['cmake .', "cmake --install . --prefix #{install_dir}"]
      end

      # Writes all source files to the file system, returning an Array of the
      # Pathnames created.
      #
      # +dir+ is the directory to write the files to. If not provided, files are
      # written to the current directory.
      #
      # Header files for the project are written into a folder named 'include',
      # which will be created if it does not exist. Other sources are written to
      # a folder named 'src' which will also be created if it doesn't exist. The
      # CMakeLists.txt file is written directly into +dir+.
      def save(dir = '.')
        dir = Pathname.new(dir) unless dir.is_a?(Pathname)
        saved_sources = build_sources.map { |it| it.save(dir) }

        headers = @source_set.lib_headers.grep_v(CSource::CExportHeader)
        unless headers.empty?
          include_dir = dir.join('include')
          FileUtils.mkdir_p(include_dir)
          saved_sources += headers.map do |it|
            it.save(include_dir)
          end
        end

        unless @source_set.lib_sources.empty?
          src_dir = dir.join('src')
          FileUtils.mkdir_p(src_dir)
          saved_sources += @source_set.lib_sources.map do |it|
            it.save(src_dir)
          end
        end

        saved_sources
      end

      # All source files in this project.
      #
      # This includes CMakeLists.txt as well as the sources of the underlying
      # project.
      def sources
        build_sources + @source_set.sources
      end

      # The headers for the library target in this project.
      def target_headers
        @source_set.lib_headers.map do |header|
          if header.is_a?(CSource::CExportHeader)
            "${PROJECT_BINARY_DIR}/include/#{header.path}"
          else
            "${#{include_dir_variable}}/#{header.path}"
          end
        end
      end

      # The include directories for the library target in this project.
      def target_include_directories
        dirs = [include_dir_variable]

        unless @source_set.lib_headers.grep(CSource::CExportHeader).empty?
          dirs << '${PROJECT_BINARY_DIR}/include'
        end

        dirs
      end
    end
  end
end
