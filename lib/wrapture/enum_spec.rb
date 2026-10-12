# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020-2026 Joel E. Anderson
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
  # A description of an enumeration.
  class EnumSpec
    include Named
    include Sourced

    # The documentation of the enumeration.
    attr_accessor :doc

    # An array of elements in this enumeration.
    attr_reader :elements

    # The name of the enumeration type.
    attr_reader :name_words

    # A map of language-specific wrapping details.
    attr_reader :source

    # Creates an EnumSpec element from +hash+.
    #
    # Element hashes have the following set of keys:
    # name:: The name used for the element, required.
    # doc:: Documentation for the element, optional.
    # value:: The value to assign to the element, optional.
    #
    # If the value is not provided, the final value of the element will be left
    # to the wrapping language if possible, and chosen by wrapture if not. This
    # means that the same element may have different values in different
    # languages if it is not specified.
    def self.element_from_hash(hash)
      element = { name: Named.words_from_name(hash[:name]) }
      element[:doc] = Comment.new(hash.fetch(:doc, ''))

      if hash.key?(:source) && hash[:source].key?(:c)
        element[:source] = { c: {} }

        if hash[:source][:c].key?(:value)
          element[:source][:c][:value] = hash[:source][:c][:value]
        end

        inc = hash[:source][:c].fetch(:includes, [])
        element[:source][:c][:includes] = Array(inc)
      end

      element
    end

    # Creates a new EnumSpec from +hash+.
    #
    # The hash must have the following keys:
    # name:: The name of the enumeration.
    # elements:: An Enumerable of element hashes contained in the enumeration.
    #            These are provided to element_from_hash to create the elements.
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this class
    def self.from_hash(hash)
      validate_hash(hash)

      enum = EnumSpec.new(hash[:name])
      enum.doc = Comment.new(hash.fetch(:doc, ''))

      if hash.key?(:source) && hash[:source].key?(:c)
        c_spec = hash[:source][:c]
        inc = Array(c_spec.fetch(:includes, []))
        enum[:c] = { includes: inc }
      end

      hash[:elements].each do |it|
        enum.elements << element_from_hash(it)
      end

      enum
    end

    # Checks +hash+ to see if it is a valid enum hash. Raises an exception if
    # it is not.
    def self.validate_hash(hash)
      unless Wrapture.supports_version?(hash.fetch(:version, Wrapture::VERSION))
        raise UnsupportedSpecVersion
      end

      unless hash.key?(:name)
        raise MissingSpecKey, 'a name is required for enumerations'
      end

      if hash.key?(:elements)
        unless hash[:elements].is_a?(Array)
          raise InvalidSpecKey, 'the elements key must be an array'
        end
      else
        raise MissingSpecKey, 'elements are required for enumerations'
      end
    end

    # An enumeration starts with a name and an empty array of elements.
    def initialize(name)
      @name_words = Named.words_from_name(name)

      # TODO: this should be an array of custom objects instead of hashes
      @elements = []

      @source = {}
    end

    # Get the source details for the given language. This is equivalent to
    # +source[lang]+.
    def [](lang)
      @source[lang]
    end

    # Set the source details for the given language. This is equivalent to
    # +source[lang]=+.
    def []=(lang, source_details)
      @source[lang] = source_details
    end
  end
end
