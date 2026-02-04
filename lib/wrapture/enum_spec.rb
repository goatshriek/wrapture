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

module Wrapture
  # A description of an enumeration.
  class EnumSpec
    include Named

    # Creates a new EnumSpec from hash +spec+.
    # TODO: remove scope argument, this should not be tracked by the enum
    def self.from_hash(spec, scope: Scope.new)
      if spec&.key?(:version) && !Wrapture.supports_version?(spec[:version])
        raise UnsupportedSpecVersion
      end

      if spec.key?(:elements)
        unless spec[:elements].is_a?(Array)
          raise InvalidSpecKey, 'the elements key must be an array'
        end
      else
        raise MissingSpecKey, 'elements are required for enumerations'
      end

      Comment.validate_doc(spec[:doc]) if spec.key?(:doc)

      name = Wrapture.normalize_name(spec, :name)
      enum = EnumSpec.new(name, scope: scope)

      enum.doc = Comment.new(spec[:doc])

      enum.namespace = spec[:namespace] if spec.key?(:namespace)

      if spec.key?(:wrapped) && spec[:wrapped].key?(:c)
        c_spec = spec[:wrapped][:c]
        if c_spec.key?(:includes)
          inc = Wrapture.normalize_array(c_spec[:includes])
          enum.wrapped[:c] = { includes: inc }
        else
          enum.wrapped[:c] = { includes: [] }
        end
      end

      spec[:elements].each do |it|
        element = { name: Wrapture.normalize_name(it, :name) }
        element[:doc] = Comment.new(it[:doc]) if it.key?(:doc)
        if it.key?(:wrapped) && it[:wrapped].key?(:c)
          element[:wrapped] = { c: {} }

          if it[:wrapped][:c].key?(:value)
            element[:wrapped][:c][:value] = it[:wrapped][:c][:value]
          end

          if it[:wrapped][:c].key?(:includes)
            inc = Wrapture.normalize_array(it[:wrapped][:c][:includes])
            element[:wrapped][:c][:includes] = inc
          end
        end

        enum.elements << element
      end

      enum
    end

    # Returns a normalized copy of a hash specification of an enumeration.
    # See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of an enumeration in place. Normalization
    # will remove duplicate entries in include lists and check for a name key.
    #
    # If the 'doc' key is present, it is validated using Comment::validate_doc.
    # If not, it is set to an empty string.
    def self.normalize_spec_hash!(spec)
      unless spec.key?(:name)
        raise MissingSpecKey, 'a name is required for enumerations'
      end

      spec[:name] = Wrapture.normalize_name(spec, :name)

      if spec.key?(:elements)
        unless spec[:elements].is_a?(Array)
          raise InvalidSpecKey, 'the elements key must be an array'
        end
      else
        raise MissingSpecKey, 'elements are required for enumerations'
      end

      if spec.key?(:doc)
        Comment.validate_doc(spec[:doc])
      else
        spec[:doc] = ''
      end

      spec[:includes] = Wrapture.normalize_array(spec[:includes])
      spec[:elements].each do |element|
        element[:includes] = Wrapture.normalize_array(element[:includes])
      end

      spec[:libraries] = Wrapture.normalize_array(spec[:libraries])

      spec
    end

    # The documentation of the enumeration.
    attr_accessor :doc

    # An array of elements in this enumeration.
    attr_reader :elements

    # The name of the constant.
    attr_reader :name_words

    # The namespace of the enumeration.
    attr_accessor :namespace

    # The scope the enumeration is in.
    attr_reader :scope

    # A map of language-specific wrapping details.
    attr_reader :wrapped

    # Creates an enumeration specification based on the provided hash spec.
    #
    # The scope can be provided if available. Otherwise, a new Scope is created
    # holding only this enumeration.
    #
    # The hash must have the following keys:
    # name:: The name of the enumeration.
    # elements:: A list of elements contained in the enumeration.
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this class
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
    def initialize(name_words, scope: Scope.new)
      @name_words = Wrapture.normalize_name_words(name_words)
      @namespace = nil

      scope << self
      @scope = scope

      # TODO: this should be an array of custom objects instead of hashes
      @elements = []

      @wrapped = {}
    end

    # An array of libraries needed for everything in this enum.
    # TODO: can we remove this?
    def libraries
      []
    end

    # True if the enumeration has a namespace, false if not.
    def namespace?
      @namespace.nil?
    end
  end
end
