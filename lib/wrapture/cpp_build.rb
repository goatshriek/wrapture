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
  # A generated C++ project along with the information required to build it.
  #
  # C++ projects are generated as individual libraries, defined by the scope
  # containing all of the specs for it.
  class CppBuild
    include Build

    # The header files for the project's library.
    attr_reader :lib_headers

    # The libraries this project's library links with.
    attr_reader :lib_links

    # The source files for the project's library.
    attr_reader :lib_sources

    # The name of the library.
    attr_reader :name

    # Create an empty C++ project.
    #
    # +name+ will be used as the name of the library the project builds.
    def initialize(name)
      @name = name
      @lib_headers = []
      @lib_links = []
      @lib_sources = []
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
    def add_link(lib)
      @lib_links << lib
    end

    # All source files (including headers) in this project.
    def sources
      @lib_headers + @lib_sources
    end
  end
end
