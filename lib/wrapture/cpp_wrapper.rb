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
    # Gives each line of the declaration of a spec to the provided block.
    def self.declare(spec, &block)
      case spec
      when ClassSpec
        declare_class(spec, &block)
      when FunctionSpec
        declare_function(spec, &block)
      end
    end

    # Gives each line of the declaration of a ClassSpec to the provided block.
    def self.declare_class(spec)
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the declaration of a FunctionSpec to the provided
    # block.
    def self.declare_function(spec)
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the definition of a spec to the provided block.
    def self.define(spec)
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the definition of a ClassSpec to the provided block.
    def self.define_class(spec)
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the definition of a EnumSpec to the provided block.
    def self.define_enum(spec)
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the definition of a FunctionSpec to the provided
    # block.
    def self.define_function(spec)
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives the symbol to use for header guard checks.
    def header_guard(spec)
      "#{spec.name.upcase}_HPP"
    end

    # Generates the C++ declaration file for the given spec, returning the name
    # of the file generated.
    # +dir+ specifies the directory that the file should be written into. The
    # default is the current working directory.
    def self.write_declaration_file(spec, dir: Dir.pwd)
      filename = "#{spec.name}.hpp"

      File.open(File.join(dir, filename), 'w') do |file|
        spec.declaration_contents { |line| file.puts(line) }
      end

      filename
    end

    # Generates the C++ definition file for the given spec, returning the name
    # of the file generated.
    # +dir+ specifies the directory that the file should be written into. The
    # default is the current working directory.
    def self.write_definition_file(spec, dir: Dir.pwd)
      filename = if spec.is_a?(EnumSpec)
                   "#{spec.name}.hpp"
                 else
                   "#{spec.name}.cpp"
                 end

      File.open(File.join(dir, filename), 'w') do |file|
        spec.definition_contents { |line| file.puts(line) }
      end

      filename
    end

    # Generates C++ source files for the given spec or scope, returning a list
    # of the files generated.
    # +dir+ specifies the directory that the files should be written into. The
    # default is the current working directory.
    def self.write_files(spec, dir: Dir.pwd)
      case spec
      when Scope
        (spec.classes + spec.enums).flat_map { |item| write_files(item) }
      when EnumSpec
        [write_definition_file(spec, dir: dir)]
      else
        [write_declaration_file(spec, dir: dir),
         write_definition_file(spec, dir: dir)]
      end
    end
  end
end
