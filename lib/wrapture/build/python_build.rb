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
    # A generated Python project along with the information required to build
    # it.
    #
    # Python projects are generated as single modules, defined by the scope
    # containing all of the specs for it.
    class PythonBuild
      include Build

      # The libraries this project's module links with.
      attr_reader :module_links

      # The source files for the module.
      attr_reader :module_sources

      # The name of the project being build
      attr_reader :name

      # Create an empty Python project.
      #
      # +name+ will be used as the name of the module the project builds.
      def initialize(name)
        @name = name
        @module_links = []
        @module_sources = []
      end

      # Add a source file to the project's module's list.
      def add_module_source(source)
        @module_sources << source
      end

      # Add a library that the project's module must be linked with.
      def add_link(lib)
        @module_links << lib
      end

      # All source files in this project.
      def sources
        @module_sources
      end
    end
  end
end
