# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2021 Joel E. Anderson
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

require 'yaml'

module Wrapture
  # Describes a scope of one or more class specifications.
  class Scope
    # Creates a scope containing all of the specs in the given files.
    def self.load_files(*filenames)
      scope = Scope.new

      filenames.each do |spec_file|
        spec = YAML.safe_load_file(spec_file)

        # TODO: this needs to be replace with a simple version check
        # to reduce duplication of this logic
        if spec.key?('version') && !Wrapture.supports_version?(spec['version'])
          raise UnsupportedSpecVersion
        end

        spec.fetch('templates', []).each do |temp_spec|
          scope << TemplateSpec.new(temp_spec)
        end

        spec.fetch('classes', []).each do |class_spec|
          scope.add_class_spec_hash(class_spec)
        end

        spec.fetch('enums', []).each do |enum_spec|
          scope.add_enum_spec_hash(enum_spec)
        end
      end

      scope
    end

    # A list of classes currently in the scope.
    attr_reader :classes

    # A list of enumerations currently in the scope.
    attr_reader :enums

    # A list of the templates defined in the scope.
    attr_reader :templates

    # Creates an empty scope, optionally with the provided specification.
    def initialize(spec = nil)
      @classes = []
      @enums = []
      @templates = []

      return if spec.nil?

      @version = Wrapture.spec_version(spec)

      @templates = spec.fetch('templates', []).collect do |template_hash|
        TemplateSpec.new(template_hash)
      end

      @classes = spec.fetch('classes', []).collect do |class_hash|
        ClassSpec.new(class_hash, scope: self)
      end

      @enums = spec.fetch('enums', []).collect do |enum_hash|
        EnumSpec.new(enum_hash)
      end
    end

    # Adds a class or template specification to the scope.
    #
    # This does not set the scope as the owner of the class for a ClassSpec.
    # This must be done during the construction of the class spec.
    def <<(spec)
      @templates << spec if spec.is_a?(TemplateSpec)
      @classes << spec if spec.is_a?(ClassSpec)
      @enums << spec if spec.is_a?(EnumSpec)

      self
    end

    # Adds a class to the scope created from the given specification hash.
    def add_class_spec_hash(spec)
      ClassSpec.new(spec, scope: self)
    end

    # Adds an enumeration to the scope created from the given specification
    # hash.
    def add_enum_spec_hash(spec)
      @enums << EnumSpec.new(spec)
    end

    # A list of includes needed to define everything in this scope.
    def definition_includes
      includes = []

      @classes.each do |class_spec|
        includes.concat(class_spec.definition_includes)
      end

      @enums.each do |enum_spec|
        includes.concat(enum_spec.definition_includes)
      end

      includes.uniq
    end

    # The name of the scope.
    def name
      @classes.first.namespace
    end

    # A list of ClassSpecs in this scope that are overloads of the given class.
    def overloads(parent)
      @classes.select { |class_spec| class_spec.overloads?(parent) }
    end

    # True if there is an overload of the given class in this scope.
    def overloads?(parent)
      @classes.any? { |class_spec| class_spec.overloads?(parent) }
    end

    # Returns the ClassSpec for the given +type+ in the scope, if one exists.
    def type(type)
      @classes.find { |class_spec| class_spec.name == type.base }
    end

    # Returns true if there is a class matching the given +type+ in this scope.
    def type?(type)
      @classes.any? { |class_spec| class_spec.name == type.base }
    end
  end
end
