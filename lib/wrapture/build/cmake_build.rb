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
    # This currently supports C and C++ libraries.
    class CmakeBuild
      include Build
      include SourceSet

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
        @source_dir = nil
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
      #
      # CMake is a common build system for C and C++ projects. It uses a file
      # named CMakeLists.txt to describe how to build a project, including
      # information about the source files and any dependencies required.
      def cmake_lists
        file = SourceFile.new('CMakeLists.txt')

        file.puts('cmake_minimum_required(VERSION 3.10)')
        file.puts("project(#{@source_set.name})")
        file.puts

        path_prefix = if @source_dir
                        file.puts("set(#{@source_set.name.upcase}_DIR")
                        file.puts("  \"#{@source_dir}\"")
                        file.puts(')')
                        file.puts

                        "${#{@source_set.name.upcase}_DIR}/"
                      else
                        ''
                      end

        header_list = "#{@source_set.name.upcase}_HEADERS"
        file.puts("set(#{header_list}")
        @source_set.lib_headers.each do |header|
          file.puts("  \"#{path_prefix}#{header.path}\"")
        end
        file.puts(')')
        file.puts

        unless @source_set.lib_sources.empty?
          source_list = "#{@source_set.name.upcase}_SOURCES"
          file.puts("set(#{source_list}")
          @source_set.lib_sources.each do |source|
            file.puts("  \"#{path_prefix}#{source.path}\"")
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
          if @source_dir
            file.puts("  PRIVATE ${#{@source_set.name.upcase}_DIR}")
          else
            file.puts('  PRIVATE ${PROJECT_SOURCE_DIR}')
          end
          file.puts(')')
          file.puts
        end

        file.puts('include(GNUInstallDirs)')
        file.puts("install(TARGETS #{@source_set.name})")
        header_dest = 'DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}'
        file.puts("install(FILES ${#{header_list}} #{header_dest})")

        file
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
        saved_build_sources = build_sources.map { |it| it.save(dir) }

        unless @source_set.lib_headers.empty?
          include_dir = dir.join('include')
          Dir.mkdir(include_dir)
          saved_headers = @source_set.lib_headers.map do |it|
            it.save(include_dir)
          end
        end

        unless @source_set.lib_sources.empty?
          src_dir = dir.join('src')
          Dir.mkdir(src_dir)
          saved_srcs = @source_set.lib_sources.map do |it|
            it.save(src_dir)
          end
        end

        saved_build_sources + saved_headers + saved_srcs
      end

      # All source files in this project.
      #
      # This includes CMakeLists.txt as well as the sources of the underlying
      # project.
      def sources
        build_sources + @source_set.sources
      end
    end
  end
end
