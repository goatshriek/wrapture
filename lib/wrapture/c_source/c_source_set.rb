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

module Wrapture
  module CSource
    # Describes a C project with all of the source files, the relationships
    # between them, and other information required to build it.
    class CSourceSet
      include SourceSet

      # The context representing what this source set implements.
      attr_reader :context

      # The header files for the project's library.
      attr_reader :lib_headers

      # The libraries this project's library links with.
      attr_reader :lib_links

      # The source files for the project's library.
      attr_reader :lib_sources

      # The name of the library.
      attr_reader :name

      # Creates a CSourceSet from a provided hash.
      def self.from_hash(spec)
        unless spec.key?(:name)
          raise(MissingSpecKey, 'a name must be given for a C library')
        end

        build = new(spec[:name])

        if spec.key?(:lib_headers)
          spec[:lib_headers].each do |it|
            build.add_lib_header(CSourceFile.new(it))
          end
        end

        if spec.key?(:lib_links)
          spec[:lib_links].each do |it|
            build.add_lib_link(it)
          end
        end

        if spec.key?(:lib_sources)
          spec[:lib_sources].each do |it|
            build.add_lib_source(CSourceFile.new(it))
          end
        end

        build
      end

      # Create an empty C project.
      #
      # +name+ will be used as the name of the library the project builds.
      def initialize(name)
        @name = name
        @lib_headers = []
        @lib_links = []
        @lib_sources = []
        @context = nil
      end

      # Add the content of another C project to this one.
      def <<(build)
        build.lib_headers.each do |hdr|
          add_lib_header(hdr)
        end

        build.lib_sources.each do |src|
          add_lib_source(src)
        end

        build.lib_links.each do |lnk|
          add_lib_link(lnk)
        end

        self
      end

      # Add a header file to the project's library's list.
      def add_lib_header(header)
        @lib_headers << header
      end

      # Add a source file to the project's library's list.
      def add_lib_source(source)
        @lib_sources << source
      end

      # Add a library that the project's libary must be linked with.
      def add_lib_link(lib)
        @lib_links << lib unless @lib_links.include?(lib)
      end

      # The includes used within this set of source files.
      #
      # Note that this is separate from the +lib_headers+ property, which
      # lists the header files this source set defines. Rather, this list
      # gives all header files that must be available when building this set
      # of source files.
      def includes
        sources.flat_map(&:includes).uniq
      end

      # All source files (including headers) in this project.
      def sources
        @lib_headers + @lib_sources
      end
    end
  end
end
