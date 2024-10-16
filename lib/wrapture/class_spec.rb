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

require 'wrapture/named'

module Wrapture
  # A description of a class, including its constants, functions, and other
  # details.
  class ClassSpec
    include Named

    # Gives the effective type of the given class spec hash.
    def self.effective_type(spec)
      inferred_pointer_wrapper = spec['constructors'].any? do |func|
        func['wrapped-function']['return']['type'] == EQUIVALENT_POINTER_KEYWORD
      end

      if spec.key?('type')
        valid_types = %w[pointer struct]
        unless valid_types.include?(spec['type'])
          type_message = "#{spec['type']} is not a valid class type"
          raise InvalidSpecKey.new(type_message, valid_keys: valid_types)
        end

        spec['type']
      elsif inferred_pointer_wrapper
        'pointer'
      else
        'struct'
      end
    end

    # Returns a normalized copy of a hash specification of a class. See
    # normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec, *templates)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)), *templates)
    end

    # Normalizes a hash specification of a class in place. Normalization checks
    # invalid keys, duplicate entries in include lists, and will set missing
    # keys to their default values (for example, an empty list if no includes
    # are given).
    #
    # A set of templates can optionally be supplied, which will be expanded in
    # the spec before normalization is done.
    #
    # If this spec cannot be normalized, for example because it is invalid or
    # it uses an unsupported version type, then an exception is raised.
    #
    # If the 'doc' key is present, it is validated using Comment::validate_doc.
    # If not, it is set to an empty string.
    def self.normalize_spec_hash!(spec, *templates)
      TemplateSpec.replace_all_uses(spec, *templates)

      raise MissingNamespace unless spec.key?('namespace')
      raise MissingSpecKey, 'name key is required' unless spec.key?('name')

      if spec.key?('doc')
        Comment.validate_doc(spec['doc'])
      else
        spec['doc'] = ''
      end

      spec['constants'] = [] unless spec.key?('constants')
      spec['constructors'] = [] unless spec.key?('constructors')
      spec['functions'] = [] unless spec.key?('functions')

      spec['version'] = Wrapture.spec_version(spec)
      spec['includes'] = Wrapture.normalize_array(spec['includes'])
      spec['libraries'] = Wrapture.normalize_array(spec['libraries'])
      spec['type'] = ClassSpec.effective_type(spec)

      if spec.key?('parent')
        includes = Wrapture.normalize_array(spec['parent']['includes'])
        spec['parent']['includes'] = includes
      end

      spec
    end

    # The list of constants in this class.
    attr_reader :constants

    # The documentation comment for this class.
    attr_reader :doc

    # The list of functions in this class.
    attr_reader :functions

    # The scope of this class.
    attr_reader :scope

    # The underlying struct of this class.
    attr_reader :struct

    # Creates a class spec based on the provided hash spec.
    #
    # The scope can be provided if available. Otherwise, a new Scope is created
    # holding only this class.
    #
    # The hash must have the following keys:
    # name:: the name of the class, in CamelCase
    # namespace:: the namespace to put the class into
    # equivalent-struct:: a hash describing the struct this class wraps
    #
    # The following keys are optional:
    # constants:: A list of constant specs that are in this class.
    # constructors:: A list of function specs that can create this class.
    # destructor:: A function spec for the destructor of the class.
    # doc:: a string containing the documentation for this class
    # functions:: A list of function specs that are in this class.
    # includes:: A list of includes that are needed for this class.
    # libraries:: A list of libraries that must be linked to use this class.
    def initialize(spec, scope: Scope.new)
      @spec = ClassSpec.normalize_spec_hash(spec, *scope.templates)

      @struct = if @spec.key?(EQUIVALENT_STRUCT_KEYWORD)
                  StructSpec.new(@spec[EQUIVALENT_STRUCT_KEYWORD])
                end

      @functions = @spec['constructors'].map do |constructor_spec|
        full_spec = constructor_spec.dup
        full_spec['name'] = @spec['name']
        full_spec['params'] = constructor_spec['wrapped-function']['params']

        FunctionSpec.new(full_spec, self, constructor: true)
      end

      if @spec.key?('destructor')
        destructor_spec = @spec['destructor'].dup
        destructor_spec['name'] = @spec['name']

        @functions << FunctionSpec.new(destructor_spec, self, destructor: true)
      end

      @spec['functions'].each do |function_spec|
        @functions << FunctionSpec.new(function_spec, self)
      end

      @constants = @spec['constants'].map do |constant_spec|
        ConstantSpec.new(constant_spec)
      end

      @doc = Comment.new(@spec['doc'])

      scope << self
      @scope = scope
    end

    # True if the class has a parent.
    def child?
      @spec.key?('parent')
    end

    # A list of constructor functions for the class.
    def constructors
      @functions.select(&:constructor?)
    end

    # A list of includes needed for the declaration of the class.
    def declaration_includes
      includes = @spec['includes'].dup

      includes.concat(@struct.includes) if @struct

      @functions.each do |func|
        includes.concat(func.declaration_includes)
      end

      @constants.each do |const|
        includes.concat(const.declaration_includes)
      end

      includes.concat(@spec['parent']['includes']) if child?

      includes.uniq
    end

    # A list of includes needed for the definition of the class.
    def definition_includes
      includes = @spec['includes'].dup

      @functions.each do |func|
        includes.concat(func.definition_includes)
      end

      @constants.each do |const|
        includes.concat(const.definition_includes)
      end

      includes.uniq
    end

    # The destructor function for the class, or nil if there isn't one.
    def destructor
      @functions.select(&:destructor?).first
    end

    # Calls the given block for each line of the class documentation.
    def documentation(&block)
      @doc&.format_as_doxygen(max_line_length: 78) { |line| block.call(line) }
    end

    # True if this class has an underlying equivalent struct member for itself.
    #
    # A class might not have an equivalent struct member even though it is
    # based on a struct. One such example is if it is able to use its parent
    # class member since the parent wraps the same struct.
    def equivalent_member?
      return false unless @struct
      return true unless child?

      parent = parent_spec

      parent.nil? ||
        parent.struct_name != struct_name ||
        parent.pointer_wrapper? != pointer_wrapper?
    end

    # True if this class can be used as a factory for children classes that it
    # overloads.
    def factory?
      @scope.overloads?(self)
    end

    # An array of libraries needed for everything in this class.
    def libraries
      @functions.flat_map(&:libraries).concat(@spec['libraries'])
    end

    # An array of methods of the class. This is a subset of the list of
    # functions without the constructors and destructors.
    #
    # Named with a specs suffix to avoid conflicts with Ruby's "methods"
    # instance method.
    def method_specs
      @functions.select { |spec| !spec.constructor? && !spec.destructor? }
    end

    # The name of the class.
    def name
      @spec['name']
    end

    # The namespace of the class.
    def namespace
      @spec['namespace']
    end

    # True if this class overloads the given one. A class is considered an
    # overload of another if it has the same equivalent struct name and
    # the equivalent struct has a set of rules. The overloaded class
    # cannot have any rules in its equivalent struct or it will not be
    # considered an overload.
    def overloads?(class_spec)
      return false unless class_spec.struct&.rules&.empty? && @struct

      class_spec.struct.name == struct_name &&
        class_spec.name == parent_name &&
        !@struct.rules.empty?
    end

    # The name of the parent of this class, or nil if there is no parent.
    def parent_name
      @spec['parent']['name'] if child?
    end

    # True if the parent of this class provides an initializer taking a pointer
    # to the same equivalent struct type.
    def parent_provides_initializer?
      return false if !pointer_wrapper? || !child?

      parent = parent_spec

      !parent.nil? &&
        parent.pointer_wrapper? &&
        parent.struct_name == @struct.name
    end

    # The class spec of the parent class, or nil if this cannot be resolved.
    def parent_spec
      type(TypeSpec.new(parent_name))
    end

    # Determines if this class is a wrapper for a struct pointer or not.
    def pointer_wrapper?
      @spec['type'] == 'pointer'
    end

    # The name of the equivalent struct of this class.
    def struct_name
      @struct.name
    end

    # Returns the ClassSpec for the given type in this class's scope.
    def type(type)
      @scope.type(type)
    end

    # Returns true if the given type exists in this class's scope.
    def type?(type)
      @scope.type?(type)
    end
  end
end
