# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2024 Joel E. Anderson
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

module Wrapture
  # A CMake project that builds a C++ library.
  class CmakeBuild
    include Build

    # Build information for the C++ library.
    attr_reader :cpp_build

    # Create a CMake build for a given C++ library build.
    def initialize(cpp_build)
      @cpp_build = cpp_build
    end

    # A CMakeLists.txt file that could be used to build this project.
    #
    # CMake is a common build system for C++ projects. It uses a file named
    # CMakeLists.txt to describe how to build a project, including information
    # about the source files and any dependencies required.
    def cmake_lists
      file = SourceFile.new('CMakeLists.txt')

      file.puts('cmake_minimum_required(VERSION 3.0.2)')
      file.puts("project(#{@cpp_build.name})")
      file.puts

      file.puts("set(#{@cpp_build.upcase}_HEADERS")
      @cpp_build.lib_headers.each do |header|
        file.puts("  #{header}")
      end
      file.puts(')')
      file.puts

      unless @cpp_build.lib_sources.empty?
        source_list = "#{@cpp_build.name.upcase}_SOURCES"
        file.puts("set(#{source_list}")
        sources.each do |source|
          file.puts("  #{source}")
        end
        file.puts(')')
        file.puts

        lib_targets = []
        @cpp_build.lib_links.each do |lib|
          target_name = "#{@cpp_build.name}_#{lib}"
          file.puts("find_library(LIB#{lib.upcase}_FOUND #{lib})")
          file.puts("add_library(#{target_name} SHARED IMPORTED)")
          file.puts("set_target_properties(#{target_name} PROPERTIES")
          file.puts("  IMPORTED_LOCATION ${LIB#{lib.upcase}_FOUND}")
          file.puts(')')
          file.puts

          lib_targets.append(target_name)
        end

        lib_deps = lib_targets.join(' ')
        file.puts("add_library(#{@cpp_build.name} ${#{source_list}})")
        file.puts("target_link_libraries(#{@cpp_build.name}")
        file.puts("  PRIVATE #{lib_deps}")
        file.puts(')')
        file.puts
      end

      file.puts('# todo add install command with headers')

      file
    end

    # All source files in this project.
    #
    # This includes CMakeLists.txt as well as the sources of the underlying
    # C++ project.
    def sources
      [cmake_lists] + @cpp_build.sources
    end
  end
end
