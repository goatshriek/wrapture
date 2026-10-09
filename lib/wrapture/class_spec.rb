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
require 'wrapture/sourced'

module Wrapture
  # A description of a class, including its constants, functions, and other
  # details.
  class ClassSpec
    include Named
    include Sourced

    # The documentation comment for this class.
    attr_accessor :doc

    # True if this is an exception class.
    attr_writer :exception

    # The words that make up the class name.
    attr_reader :name_words

    # The name words of the parent of this class, or nil if it has no parent.
    attr_accessor :parent

    # A map of language-specific wrapping details.
    attr_reader :source

    # Creates a new ClassSpec from hash +spec+.
    #
    # The hash must have a +:name+ key with a String or Enumerable of strings as
    # the value, which will be used as the name of the ClassSpec.
    #
    # The following symbol key names are optional:
    # doc:: A string containing the documentation for this class.
    # exception:: If set to true, this will be made an exception class.
    # parent:: Either a Hash with a +:name+ key, or a name value
    #          directly. The name must be a String or Enumerable of strings with
    #          the name of the parent of this class.
    def self.from_hash(spec)
      unless Wrapture.supports_version?(spec.fetch(:version, Wrapture::VERSION))
        raise UnsupportedSpecVersion
      end

      unless spec.key?(:name)
        raise(MissingSpecKey, 'ClassSpec hashes must have a :name key')
      end

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

      # TODO: pick up here, validating intializers entries, and moving hash
      # validations to their own validate function

      class_spec = new(spec[:name])
      class_spec.doc = Comment.new(spec.fetch(:doc, ''))
      class_spec.exception = true if spec.fetch(:exception, false)
      if spec.key?(:parent)
        class_spec.parent = if spec[:parent].is_a?(Hash)
                              Named.words_from_name(spec[:parent][:name])
                            else
                              Named.words_from_name(spec[:parent])
                            end
      end
      set_source_from_hash(class_spec, spec.fetch(:source, {}))

      class_spec
    end

    # Sets the members of the +source+ property of the +FunctionSpec+ +spec+
    # based on the contents of +hash+.
    private_class_method def self.set_source_from_hash(spec, hash)
      return unless hash.key?(:c)

      if hash[:c].key?(:pointer)
        struct_type = CSource::CStruct.from_hash(hash[:c][:pointer])
        spec[:c] = CSource::CPointer.new(struct_type)
      else
        spec[:c] = CSource::CStruct.from_hash(hash[:c])
      end
    end

    # A new class has +name+, an empty documentation comment, no parent, and
    # exception set to false.
    def initialize(name)
      @name_words = Named.words_from_name(name)
      @doc = Comment.new
      @exception = false
      @parent = nil
      @source = {}
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
      @exception
    end
  end
end
