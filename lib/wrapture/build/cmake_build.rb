# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
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
#++

module Wrapture
  module Build
    # A CMake project that builds a library.
    #
    # This currently supports C and C++ libraries.
    class CmakeBuild
      include Build

      # The build information for the source code of the library.
      attr_reader :build_info

      # Creates a CMake build from a provided hash.
      def self.from_hash(spec)
        unless spec.key?(:c_build) || spec.key?(:cpp_build)
          raise(MissingSpecKey,
                'an underlying c or c++ build must be specified')
        end

        build_info = if spec.key?(:c_build)
                       CBuild.from_hash(spec[:c_build])
                     else
                       CppBuild.from_hash(spec[:cpp_build])
                     end

        new(build_info)
      end

      # Create a CMake build for a given library build.
      def initialize(build_info)
        @build_info = build_info
      end

      # A CMakeLists.txt file that could be used to build this project.
      #
      # CMake is a common build system for C and C++ projects. It uses a file
      # named CMakeLists.txt to describe how to build a project, including
      # information about the source files and any dependencies required.
      def cmake_lists
        file = SourceFile.new('CMakeLists.txt')

        file.puts('cmake_minimum_required(VERSION 3.10)')
        file.puts("project(#{@build_info.name})")
        file.puts

        file.puts("set(#{@build_info.name.upcase}_HEADERS")
        @build_info.lib_headers.each do |header|
          file.puts("  #{header.path}")
        end
        file.puts(')')
        file.puts

        unless @build_info.lib_sources.empty?
          source_list = "#{@build_info.name.upcase}_SOURCES"
          file.puts("set(#{source_list}")
          @build_info.lib_sources.each do |source|
            file.puts("  #{source.path}")
          end
          file.puts(')')
          file.puts

          lib_targets = []
          @build_info.lib_links.each do |lib|
            target_name = "#{@build_info.name}_#{lib}"
            file.puts("find_library(LIB#{lib.upcase}_FOUND #{lib})")
            file.puts("add_library(#{target_name} SHARED IMPORTED)")
            file.puts("set_target_properties(#{target_name} PROPERTIES")
            file.puts("  IMPORTED_LOCATION ${LIB#{lib.upcase}_FOUND}")
            file.puts(')')
            file.puts

            lib_targets.append(target_name)
          end

          lib_deps = lib_targets.join(' ')
          file.puts("add_library(#{@build_info.name} ${#{source_list}})")
          file.puts("target_link_libraries(#{@build_info.name}")
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
      # project.
      def sources
        [cmake_lists] + @build_info.sources
      end
    end
  end
end
