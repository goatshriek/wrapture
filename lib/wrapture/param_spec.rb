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

      unless spec_hash.key?(:type)
        raise(MissingSpecKey, 'ParamSpec hashes must have a :type key')
      end

      spec = new(spec_hash[:name], TypeSpec.new(spec_hash[:type]))
      spec.default_value = spec_hash.fetch(:default_value, nil)

      spec
    end

    # Creages an Array of new ParamSpecs from the provided Enumerable of
    # hashes.
    def self.new_list(spec_hashes)
      spec_hashes.map { |it| from_hash(it) }
    end

    # Returns a normalized copy of a list of parameter hash specifications in
    # place.
    #
    # Multiple variadic parameters (named '...') will be removed and only the
    # first used. If the variadic parameter is not last, it will be moved to
    # the end of the list.
    def self.normalize_param_list(spec_list)
      if spec_list.nil?
        []
      elsif spec_list.none? { |spec| spec[:name] == '...' }
        spec_list.map { |spec| normalize_spec_hash(spec) }
      else
        error_msg = "'...' may not be the only parameter"
        raise(InvalidSpecKey, error_msg) if spec_list.one?

        i = spec_list.find_index { |spec| spec[:name] == '...' }
        var = spec_list[i]

        spec_list
          .reject { |spec| spec[:name] == '...' }
          .map { |spec| normalize_spec_hash(spec) }
          .push(var)
      end
    end

    # Returns a normalized copy of the hash specification of a parameter in
    # +spec+. See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes the hash specification of a parameter in +spec+ in place.
    # Normalization will remove duplicate entries from include lists and
    # validate that required key values are set.
    def self.normalize_spec_hash!(spec)
      Comment.validate_doc(spec[:doc]) if spec.key?(:doc)
      spec[:includes] = Wrapture.normalize_array(spec[:includes])

      spec[:type] = '...' if spec[:name] == '...'

      unless spec.key?(:type)
        missing_type_msg = 'parameters must have a type key defined'
        raise(MissingSpecKey, missing_type_msg)
      end

      spec
    end

    # A string with a comma-separated list of parameters (using resolved type)
    # and names, fit for use in a function signature or declaration. param_list
    # must be a list of ParamSpec instances, and owner must be the FunctionSpec
    # that the parameters belong to.
    def self.signature(param_list, owner)
      if param_list.empty?
        'void'
      else
        param_list.map { |param| param.signature(owner) }.join(', ')
      end
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
      @default_value.nil?
    end

    # True if this parameter is variadic (the name is equal to '...').
    def variadic?
      @type_spec.variadic?
    end
  end
end
