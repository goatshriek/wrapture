# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2025 Joel E. Anderson
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

    # The list of constants in this class.
    attr_reader :constants

    # The documentation comment for this class.
    attr_reader :doc

    # The list of functions in this class.
    attr_reader :functions

    # The scope of this class.
    attr_reader :scope

    # The underlying struct of this class.
    # attr_reader :struct

    # A map of language-specific wrapping details.
    attr_accessor :wrapped

    # Gives the effective type of the given class spec hash.
    # TODO: this should be refactored to use an object instead of a hash
    def self.effective_type(spec)
      inferred_pointer_wrapper = spec[:constructors].any? do |func|
        # TODO: this should not have c-specific code
        func[:wrapped].key?(:c) &&
          func[:wrapped][:c][:return][:type] == EQUIVALENT_POINTER_KEYWORD
      end

      if spec.key?(:type)
        valid_types = %w[pointer struct]
        unless valid_types.include?(spec[:type])
          type_message = "#{spec[:type]} is not a valid class type"
          raise InvalidSpecKey.new(type_message, valid_keys: valid_types)
        end

        spec[:type]
      elsif inferred_pointer_wrapper
        'pointer'
      else
        'struct'
      end
    end

    # Creates a new ClassSpec from hash +spec+.
    def self.from_hash(spec)
      if spec.key?(:constructors)
        c_constructors = spec[:constructors].reject do |it|
          it.dig(:wrapped, :c).nil?
        end
        if c_constructors.any? do |it|
          it.dig(:wrapped, :c, :return, :type).nil?
        end
          raise InvalidConstructor, 'a constructor did not have a return type'
        end
      end

      class_spec = new(spec)

      if spec.key?(:wrapped) && spec[:wrapped].key?(:c)
        if spec[:wrapped][:c].key?(:pointer)
          struct_type = CSource::CStruct.from_hash(spec[:wrapped][:c][:pointer])
          class_spec[:c] = CSource::CPointer.new(struct_type)
        else
          class_spec[:c] = CSource::CStruct.from_hash(spec[:wrapped][:c])
        end
      end

      class_spec
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

      raise MissingNamespace unless spec.key?(:namespace)
      raise MissingSpecKey, 'name key is required' unless spec.key?(:name)

      spec[:name] = Wrapture.normalize_name(spec, :name)

      if spec.key?(:doc)
        Comment.validate_doc(spec[:doc])
      else
        spec[:doc] = ''
      end

      spec[:constants] = [] unless spec.key?(:constants)
      spec[:constructors] = [] unless spec.key?(:constructors)
      spec[:functions] = [] unless spec.key?(:functions)

      spec[:version] = Wrapture.spec_version(spec)
      spec[:includes] = Wrapture.normalize_array(spec[:includes])
      spec[:libraries] = Wrapture.normalize_array(spec[:libraries])
      spec[:type] = ClassSpec.effective_type(spec)

      if spec.key?(:parent)
        includes = Wrapture.normalize_array(spec[:parent][:includes])
        spec[:parent][:includes] = includes
      end

      spec[:exception] = if spec.key?(:exception) && spec[:exception]
                           true
                         else
                           false
                         end

      spec
    end

    # Creates a class spec based on the provided hash spec.
    #
    # The scope can be provided if available. Otherwise, a new Scope is created
    # holding only this class.
    #
    # The hash must have the following keys:
    # name:: the name of the class, in CamelCase
    # namespace:: the namespace to put the class into
    # equivalent_struct:: a hash describing the struct this class wraps
    #
    # The following keys are optional:
    # constants:: A list of constant specs that are in this class.
    # constructors:: A list of function specs that can create this class.
    # destructor:: A function spec for the destructor of the class.
    # doc:: A string containing the documentation for this class.
    # exception:: If set to true, this will be made an exception class.
    # functions:: A list of function specs that are in this class.
    # includes:: A list of includes that are needed for this class.
    # libraries:: A list of libraries that must be linked to use this class.
    def initialize(spec, scope: Scope.new)
      @spec = ClassSpec.normalize_spec_hash(spec, *scope.templates)

      @functions = @spec[:constructors].map do |constructor_spec|
        full_spec = constructor_spec.dup
        full_spec[:name] = @spec[:name]
        # TODO: there shouldn't be C-specific code here
        if constructor_spec[:wrapped].key?(:c)
          full_spec[:params] = constructor_spec[:wrapped][:c][:params]
        end
        full_spec[:constructor] = true

        func_spec = FunctionSpec.from_hash(full_spec)
        func_spec.owner = self

        func_spec
      end

      if @spec.key?(:destructor)
        destructor_spec = @spec[:destructor].dup
        destructor_spec[:name] = @spec[:name]
        destructor_spec[:destructor] = true

        func_spec = FunctionSpec.from_hash(destructor_spec)
        func_spec.owner = self
        @functions << func_spec
      end

      @spec[:functions].each do |function_spec|
        func_spec = FunctionSpec.from_hash(function_spec)
        func_spec.owner = self
        @functions << func_spec
      end

      @constants = @spec[:constants].map do |constant_spec|
        ConstantSpec.new(constant_spec)
      end

      @doc = Comment.new(@spec[:doc])

      scope << self
      @scope = scope

      @wrapped = {}
      if @spec.key?(:wrapped) && @spec[:wrapped].key?(:c)
        if @spec[:wrapped][:c].key?(:pointer)
          struct_type = CSource::CStruct.from_hash(spec[:wrapped][:c][:pointer])
          @wrapped[:c] = CSource::CPointer.new(struct_type)
        else
          @wrapped[:c] = CSource::CStruct.from_hash(spec[:wrapped][:c])
        end
      end
    end

    # Get the wrapping details for the given language. This is equivalent to
    # +wrapped[lang]+.
    def [](lang)
      @wrapped[lang]
    end

    # Set the wrapping details for the given language. This is equivalent to
    # +wrapped[lang]=+.
    def []=(lang, wrapped_function)
      @wrapped[lang] = wrapped_function
    end

    # True if the class has a parent.
    def child?
      @spec.key?(:parent)
    end

    # A list of constructor functions for the class.
    def constructors
      @functions.select(&:constructor?)
    end

    # True if this class can be defined.
    def definable?
      @functions.all?(&:definable?)
    end

    # The destructor function for the class, or nil if there isn't one.
    def destructor
      @functions.select(&:destructor?).first
    end

    # True if this class is an exception.
    def exception?
      @spec[:exception]
    end

    # An array of libraries needed for everything in this class.
    def libraries
      @functions.flat_map(&:libraries).concat(@spec[:libraries])
    end

    # An array of methods of the class. This is a subset of the list of
    # functions without the constructors and destructors.
    #
    # Named with a specs suffix to avoid conflicts with Ruby's "methods"
    # instance method.
    def method_specs
      @functions.select { |spec| !spec.constructor? && !spec.destructor? }
    end

    # The words that make up the function name.
    def name_words
      @spec[:name]
    end

    # The namespace of the class.
    def namespace
      @spec[:namespace]
    end

    # True if this class is a parent of others.
    def parent?
      @scope.classes.any? do |class_spec|
        class_spec.parent_name == name
      end
    end

    # The name of the parent of this class, or nil if there is no parent.
    def parent_name
      # TODO: this needs to use the actual class spec method instead of the hash
      @spec[:parent][:name] if child?
    end

    # The class spec of the parent class, or nil if this cannot be resolved.
    def parent_spec
      type(TypeSpec.new(parent_name))
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
