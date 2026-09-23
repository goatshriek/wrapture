# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2026 Joel E. Anderson
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

    # The documentation comment for this class.
    attr_reader :doc

    # The name words of the parent of this class, or nil if it has no parent.
    attr_reader :parent

    # A map of language-specific wrapping details.
    attr_reader :source

    # Gives the effective type of the given class spec hash.
    # TODO: this should be refactored to use an object instead of a hash
    def self.effective_type(spec)
      inferred_pointer_wrapper = spec[:constructors].any? do |func|
        # TODO: this should not have c-specific code
        func[:source].key?(:c) &&
          func[:source][:c][:return][:type] == EQUIVALENT_POINTER_KEYWORD
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
          it.dig(:source, :c).nil?
        end
        if c_constructors.any? do |it|
          it.dig(:source, :c, :return, :type).nil?
        end
          raise InvalidConstructor, 'a constructor did not have a return type'
        end
      end

      class_spec = new(spec)

      if spec.key?(:source) && spec[:source].key?(:c)
        if spec[:source][:c].key?(:pointer)
          struct_type = CSource::CStruct.from_hash(spec[:source][:c][:pointer])
          class_spec[:c] = CSource::CPointer.new(struct_type)
        else
          class_spec[:c] = CSource::CStruct.from_hash(spec[:source][:c])
        end
      end

      class_spec
    end

    # Returns a normalized copy of a hash specification of a class. See
    # normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of a class in place. Normalization checks
    # invalid keys, duplicate entries in include lists, and will set missing
    # keys to their default values (for example, an empty list if no includes
    # are given).
    #
    # If this spec cannot be normalized, for example because it is invalid or
    # it uses an unsupported version type, then an exception is raised.
    #
    # If the 'doc' key is present, it is validated using Comment::validate_doc.
    # If not, it is set to an empty string.
    def self.normalize_spec_hash!(spec)
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
    def initialize(spec)
      @spec = ClassSpec.normalize_spec_hash(spec)
      @doc = Comment.new(@spec[:doc])

      @source = {}
      if @spec.key?(:source) && @spec[:source].key?(:c)
        if @spec[:source][:c].key?(:pointer)
          struct_type = CSource::CStruct.from_hash(spec[:source][:c][:pointer])
          @source[:c] = CSource::CPointer.new(struct_type)
        else
          @source[:c] = CSource::CStruct.from_hash(spec[:source][:c])
        end
      end

      @parent = if @spec.key?(:parent) && @spec[:parent].key?(:name)
                  name = @spec[:parent][:name]
                  if name.is_a?(String)
                    Named.words_from_name(name)
                  else
                    Wrapture.normalize_name_words(name)
                  end
                end
    end

    # Get the wrapping details for the given language. This is equivalent to
    # +source[lang]+.
    def [](lang)
      @source[lang]
    end

    # Set the wrapping details for the given language. This is equivalent to
    # +source[lang]=+.
    def []=(lang, source_struct)
      @source[lang] = source_struct
    end

    # True if the class has a parent.
    def child?
      !@parent.nil?
    end

    # True if this class is an exception.
    def exception?
      @spec[:exception]
    end

    # The words that make up the function name.
    def name_words
      @spec[:name]
    end
  end
end
