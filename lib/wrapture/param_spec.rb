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

require 'wrapture/type_spec'

module Wrapture
  # A description of a parameter used in a function.
  class ParamSpec
    include Named

    # The default value for the parameter, or nil if there is not one.
    attr_accessor :default_value

    # The documentation for the parameter.
    attr_accessor :doc

    # The name words that make up the parameter name.
    attr_reader :name_words

    # The type of the parameter.
    attr_accessor :type_spec

    # Creates a new ParamSpec from the hash +spec_hash+.
    #
    # The hash must have a +:name+ key with a String or Enumerable of strings as
    # the value, which will be used as the name of the ParamSpec. It also must
    # have a +:type+ key, the value of which will be passed to
    # TypeSpec::from_hash to construct the type.
    def self.from_hash(spec_hash)
      unless spec_hash.key?(:name)
        raise(MissingSpecKey, 'ParamSpec hashes must have a :name key')
      end

      unless spec_hash.key?(:type) || spec_hash[:name] == '...'
        msg = 'ParamSpec hashes must either be variadic (named \'...\') or ' \
              'have a :type key'
        raise(MissingSpecKey, msg)
      end

      spec = new(spec_hash[:name], TypeSpec.new(spec_hash[:type]))
      spec.default_value = spec_hash.fetch(:default_value, nil)

      spec
    end

    # Creages an Array of new ParamSpecs from the provided Enumerable of
    # hashes.
    def self.from_hashes(spec_hashes)
      spec_hashes.map { |it| from_hash(it) }
    end

    # A parameter must have a +name+ and +type_spec+, and starts with a nil
    # default_value and an empty doc Comment. +type_spec+ will be used directly
    # if it is a TypeSpec instance, otherwise it is passed to the TypeSpec
    # constructor.
    def initialize(name, type_spec)
      @name_words = Named.words_from_name(name)
      @type_spec = if type_spec.is_a?(TypeSpec)
                     type_spec
                   else
                     TypeSpec.new(type_spec)
                   end

      @default_value = nil
      @doc = Comment.new
    end

    # True if this param has a default value.
    def default_value?
      !@default_value.nil?
    end

    # True if this parameter is variadic (the name is equal to '...').
    def variadic?
      @name_words == ['...']
    end
  end
end
