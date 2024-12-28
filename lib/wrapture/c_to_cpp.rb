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
  # A collection of wrappers for generating C++ wrappers for C code.
  module CToCpp
    # Generate a source file with the declaration of a class.
    def self.declare_class(class_spec)
      src = SourceFile.new("#{class_spec.name}.hpp")

      wrapper = CToCppWrapper.new(class_spec)
      wrapper.declare do |line|
        src.puts(line)
      end

      src
    end

    # Generate a source file with the definition of a class.
    def self.define_class(class_spec)
      src = SourceFile.new("#{class_spec.name}.cpp")

      wrapper = CToCppWrapper.new(class_spec)
      wrapper.define do |line|
        src.puts(line)
      end

      src
    end

    # Generates a build for a C++ library wrapping a class.
    def self.wrap_class(class_spec)
      build = CppBuild.new(class_spec.name)

      build.add_lib_header(declare_class(class_spec))
      build.add_lib_source(define_class(class_spec))

      # TODO: collect libraries that the class relies on for linking

      build
    end

    # Generates a build for a C++ library wrapping the provided enum.
    def self.wrap_enum(enum_spec)
      CppBuild.new(enum_spec.name)

      # TODO: implement
    end

    # Generates a build for a C++ library wrapping the provided scope.
    #
    # +scope+ describes all of the classes and other entities that will be
    # wrapped. These will all be put into a namespace named after the scope.
    def self.wrap_scope(scope)
      CppBuild.new(scope.name)

      # TODO: implement
    end
  end
end
