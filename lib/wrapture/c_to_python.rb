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
  # A collection of wrappers for generating Python wrappers for C code.
  module CToPython
    # Generates a source file with the definition of a module for a scope.
    def self.define_module(scope)
      src = CSource::CSourceFile.new("#{scope.name}.c")

      src.puts('#define PY_SSIZE_T_CLEAN')
      src.include('Python.h')

      # TODO: only include this if it's needed
      # src.puts('// for offsetof()')
      src.include('stddef.h', comment: Comment.new('for offsetof()'))

      scope.definition_includes.each { |inc| src.include(inc) }

      wrapper = CToPythonWrapper.new(scope)
      wrapper.define_module do |line|
        src.puts(line)
      end

      src
    end

    # Generates a build for a Python library wrapping the provided scope.
    #
    # +scope+ describes all of the classes and other entities that will be
    # wrapped. These will all be put into a namespace named after the scope.
    def self.wrap_scope(scope)
      build = PythonBuild.new(scope.name)

      build.add_module_source(define_module(scope))

      scope.libraries.each do |lib|
        build.add_link(lib)
      end

      build
    end
  end
end
