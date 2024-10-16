# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020-2023 Joel E. Anderson
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
      unless spec.key?('name')
        raise MissingSpecKey, 'a name is required for enumerations'
      end

      if spec.key?('elements')
        unless spec['elements'].is_a?(Array)
          raise InvalidSpecKey, 'the elements key must be an array'
        end
      else
        raise MissingSpecKey, 'elements are required for enumerations'
      end

      if spec.key?('doc')
        Comment.validate_doc(spec['doc'])
      else
        spec['doc'] = ''
      end

      spec['includes'] = Wrapture.normalize_array(spec['includes'])
      spec['elements'].each do |element|
        element['includes'] = Wrapture.normalize_array(element['includes'])
      end

      spec['libraries'] = Wrapture.normalize_array(spec['libraries'])

      spec
    end

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
    def initialize(spec, scope: Scope.new)
      @spec = EnumSpec.normalize_spec_hash(spec)
      @doc = Comment.new(@spec['doc'])

      scope << self
      @scope = scope
    end

    # The documentation of the enumeration.
    attr_reader :doc

    # A list of the includes needed for the definition of the enumeration.
    def definition_includes
      includes = @spec['includes'].dup

      @spec['elements'].each do |element|
        includes.concat(element['includes'])
      end

      includes.uniq
    end

    # A list of elements in this enumeration.
    # TODO: This should be redefined as a separate type of spec
    # instead of being a raw array of hashes.
    def elements
      @spec['elements']
    end

    # An array of libraries needed for everything in this enum.
    def libraries
      @spec['libraries']
    end

    # The name of the enumeration.
    def name
      @spec['name']
    end

    # The namespace of the enumeration, or nil if it does not have one.
    def namespace
      @spec.fetch('namespace', nil)
    end

    # True if the enumeration has a namespace, false if not.
    def namespace?
      @spec.key?('namespace')
    end
  end
end
