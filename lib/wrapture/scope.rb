# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2023 Joel E. Anderson
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
    include Enumerable
    include Named

    # Creates a scope containing all of the specs in the given files.
    def self.load_files(*filenames)
      scope = Scope.new

      filenames.each do |spec_file|
        scope.merge_file(spec_file)
      end

      scope
    end

    # Returns a normalized copy of a scope hash specification. See
    # normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec, *templates)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)), *templates)
    end

    # Normalizes a hash specification of a scope in place. Normalization
    # will normalize the version of the spec and all templates, classes,
    # and enumerations as well.
    #
    # A set of templates can optionally be supplied, which will be expanded in
    # the spec before normalization is done.
    #
    # If the 'doc' key is present, it is validated using Comment::validate_doc.
    # If not, it is set to an empty string.
    def self.normalize_spec_hash!(spec, *templates)
      # the templates must be handled first, since they might add keys needed
      # for the spec to be valid
      TemplateSpec.replace_all_uses(spec, *templates)
      spec['templates'] = [] unless spec.key?('templates')
      new_templates = spec['templates'].collect do |template_hash|
        TemplateSpec.new(template_hash)
      end
      TemplateSpec.replace_all_uses(spec, *new_templates)

      if spec.key?('doc')
        Comment.validate_doc(spec['doc'])
      else
        spec['doc'] = ''
      end

      spec['version'] = Wrapture.spec_version(spec)

      spec['classes'] = [] unless spec.key?('classes')
      spec['classes'].each do |class_hash|
        ClassSpec.normalize_spec_hash!(class_hash)
      end

      spec['enums'] = [] unless spec.key?('enums')
      spec['enums'].each do |enum_hash|
        EnumSpec.normalize_spec_hash!(enum_hash)
      end

      spec
    end

    # A list of classes currently in the scope.
    attr_reader :classes

    # The documentation comment for this scope.
    attr_reader :doc

    # A list of enumerations currently in the scope.
    attr_reader :enums

    # A list of the templates defined in the scope.
    attr_reader :templates

    # Creates an empty scope, optionally with the provided specification.
    #
    # Since a scope can be completely empty, all of the following keys are
    # optional in the specification hash.
    # doc:: a string containing the documentation for this class
    # name:: the explicit name of this scope
    def initialize(spec = {})
      @classes = []
      @enums = []
      @templates = []

      @spec = self.class.normalize_spec_hash(spec)
      @doc = Comment.new(@spec['doc'])

      @templates = @spec['templates'].collect do |template_hash|
        TemplateSpec.new(template_hash)
      end

      @spec['classes'].each do |class_hash|
        ClassSpec.new(class_hash, scope: self)
      end

      @spec['enums'].each do |enum_hash|
        EnumSpec.new(enum_hash, scope: self)
      end
    end

    # Adds a class or template specification to the scope.
    #
    # This does not set the scope as the owner of the class for a ClassSpec,
    # which must be done during the construction of the class spec.
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

    # An array of includes needed to define everything in this scope.
    def definition_includes
      flat_map(&:definition_includes).uniq
    end

    # Yields successive specs in this scope.
    def each(&block)
      @classes.each(&block)
      @enums.each(&block)

      self
    end

    # An array of libraries needed for everything in this scope.
    def libraries
      flat_map(&:libraries).uniq
    end

    # Merges the scope defined in the given filename into this one.
    #
    # If the new spec specifies a name and this spec already has one that is
    # different, this will raise a KeyConflict error.
    #
    # The documentation strings are joined with two newline characters, unless
    # one of them is empty, in which case the non-empty one is used.
    #
    # The version of spec will be the maximum of this scope and the loaded one.
    # Note that the version defaults to the current Wrapture version if one is
    # not provided, meaning that if the version was not given in both specs
    # then this will be the current Wrapture version.
    def merge_file(spec_filename)
      new_spec = YAML.safe_load_file(spec_filename)
      self.class.normalize_spec_hash!(new_spec, *@templates)

      both_named = @spec.key?('name') && new_spec.key?('name')
      if both_named && @spec['name'] != new_spec['name']
        msg = "'#{new_spec['name']}' conflicts current name '#{@spec['name']}'"
        raise KeyConflict, msg
      end

      versions = [@spec['version'], new_spec['version']]
      @spec['version'] = Wrapture.max_version(*versions)

      new_doc = Comment.new(new_spec['doc'])
      unless new_doc.empty?
        if @doc.empty?
          @doc = new_doc
        else
          @doc << '\n\n' << new_doc
        end
      end

      new_spec['templates'].each do |template_hash|
        @templates << TemplateSpec.new(template_hash)
      end

      new_spec['classes'].each do |class_hash|
        ClassSpec.new(class_hash, scope: self)
      end

      new_spec['enums'].each do |enum_hash|
        EnumSpec.new(enum_hash, scope: self)
      end

      self
    end

    # The name of the scope.
    #
    # Since the name of a scope is optional, it is derived using the following
    # rules:
    # * the value of the 'name' key in the scope's definition if present
    # * the first namespace found in a sequential search of the scope's classes
    # * the first namespace found in a sequential search of the scope's enums
    # * the name of the first class in the scope
    # * the name of the first enum in the scope
    # * an empty string
    def name
      return @spec['name'] if @spec.key?('name')

      @classes.each do |class_spec|
        return class_spec.namespace unless class_spec.namespace.nil?
      end

      @enums.each do |enum_spec|
        return enum_spec.namespace unless enum_spec.namespace.nil?
      end

      if @classes.any?
        @classes.first.name
      elsif @enums.any?
        @enums.first.name
      else
        ''
      end
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
      name = case type
             when TypeSpec
               type.base
             when String
               type
             else
               type.to_s
             end

      @classes.find { |class_spec| class_spec.name == name }
    end

    # Returns true if there is a class matching the given +type+ in this scope.
    def type?(type)
      name = case type
             when TypeSpec
               type.base
             when String
               type
             else
               type.to_s
             end

      @classes.any? { |class_spec| class_spec.name == name }
    end
  end
end
