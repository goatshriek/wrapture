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
  # A description of a constant.
  class ConstantSpec
    include Named
    include Sourced

    # The documentation comment for this constant.
    attr_accessor :doc

    # The words that make up the class name.
    attr_reader :name_words

    # A map of language-specific wrapping details.
    attr_reader :source

    # The type of this constant.
    attr_reader :type_spec

    # The value of this constant.
    attr_reader :value

    # Creates a new ConstantSpec from +hash+.
    #
    # The hash must have the following keys (symbols with this name):
    # name:: the name of the constant
    # type:: the type of the constant
    # value:: the value to assign to the constant
    # includes::  a list of includes that need to be added in order for this
    # constant to be valid (for example, includes for the type and value).
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this constant
    def self.from_hash(hash)
      validate_hash(hash)

      spec = new(hash[:name], hash[:type], hash[:value])
      spec.doc = Comment.new(hash.fetch(:doc, ''))

      unless hash.dig(:source, :c, :includes).nil?
        spec.source[:c] = { includes: Array(hash[:source][:c][:includes]) }
      end

      spec
    end

    # Checks +hash+ to see if it is a valid class hash. Raises an exception if
    # it is not.
    def self.validate_hash(hash)
      unless Wrapture.supports_version?(hash.fetch(:version, Wrapture::VERSION))
        raise UnsupportedSpecVersion
      end

      %i[name type value].each do |it|
        unless hash.key?(it)
          raise(MissingSpecKey, "ConstantSpec hashes must have a :#{it} key")
        end
      end
    end

    # A constant must have +name+, +type_spec+, and +value+.
    def initialize(name, type_spec, value)
      @name_words = Named.words_from_name(name)
      @type_spec = if type_spec.is_a?(TypeSpec)
                     type_spec
                   else
                     TypeSpec.new(type_spec)
                   end

      @doc = Comment.new
      @source = {}
      @value = value
    end
  end
end
