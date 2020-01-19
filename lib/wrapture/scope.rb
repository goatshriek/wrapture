# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2020 Joel E. Anderson
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

module Wrapture
  # Describes a scope of one or more class specifications.
  class Scope
    # A list of classes currently in the scope.
    attr_reader :classes

    # Creates an empty scope with no classes in it.
    def initialize(spec = nil)
      @classes = []
      @templates = []

      return if spec.nil? || !spec.key?('classes')

      @version = Wrapture.spec_version(spec)

      @templates = spec.fetch('templates', []).map do |template_hash|
        TemplateSpec.new(template_hash)
      end

      class_specs = spec['classes'].dup
      @templates.each { |temp| temp.replace_uses(class_specs) }

      @classes = class_specs.collect do |class_hash|
        ClassSpec.new(class_hash, scope: self)
      end
    end

    # Adds a class or template specification to the scope.
    #
    # This does not set the scope as the owner of the class for a ClassSpec.
    # This must be done during the construction of the class spec.
    def <<(spec)
      @templates << spec if spec.is_a?(TemplateSpec)
      @classes << spec if spec.is_a?(ClassSpec)
    end

    # Adds a class to the scope created from the given specification hash.
    def add_class_spec_hash(spec)
      class_hash = Marshal.load(Marshal.dump(spec))

      @templates.each { |temp| temp.replace_uses(class_hash) }

      @classes << ClassSpec.new(class_hash, scope: self)
    end

    # Generates the wrapper class files for all classes in the scope.
    def generate_wrappers
      files = []

      @classes.each do |class_spec|
        files.concat(class_spec.generate_wrappers)
      end

      files
    end

    # A list of ClassSpecs in this scope that are overloads of the given class.
    def overloads(parent)
      @classes.select { |class_spec| class_spec.overloads?(parent) }
    end

    # True if there is an overload of the given class in this scope.
    def overloads?(parent)
      @classes.any? { |class_spec| class_spec.overloads?(parent) }
    end

    # Returns the ClassSpec for the given type in the scope.
    def type(type)
      @classes.find { |class_spec| class_spec.name == type }
    end

    # Returns true if the given type is in the scope.
    def type?(type)
      @classes.each do |class_spec|
        return true if class_spec.name == type
      end

      false
    end
  end
end
