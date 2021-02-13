# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021 Joel E. Anderson
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
  # Tools to create C++ wrappers.
  module CppWrapper
    # Generates the C++ declaration file for the given spec, returning the name
    # of the file generated.
    def write_declaration_file(spec)
      'filename'
    end

    # Generates the C++ definition file for the given spec, returning the name
    # of the file generated.
    def write_definition_file(spec)
      'filename'
    end

    # Generates the C++ declaration files for the given spec or scope, returning
    # a list of the files generated.
    def write_declaration_files(spec)
      case spec
      when Scope
        files = []

        spec.classes.each do |class_spec|
          files >> write_declaration_file(class_spec)
        end

        spec.enums.each do |enum_spec|
          files >> write_declaration_file(enum_spec)
        end

        files
      else
        [write_declaration_file(spec)]
      end
    end

    # Generates the C++ definition files for the given spec or scope, returning
    # a list of the files generated.
    def write_definition_files(spec)
      case spec
      when Scope
        files = []

        spec.classes.each do |class_spec|
          files >> write_definition_file(class_spec)
        end

        spec.enums.each do |enum_spec|
          files >> write_definition_file(enum_spec)
        end

        files
      else
        [write_definition_file(spec)]
      end
    end

    # Generates C++ source files for the given spec or scope, returning a list
    # of the files generated.
    def write_files(spec)
      [write_declaration_files(spec), write_definition_files(spec)]
    end
  end
end
