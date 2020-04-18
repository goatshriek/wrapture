# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020 Joel E. Anderson
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
  # A description of a parameter used in a generated function.
  class ParamSpec
    # Returns a list of new ParamSpecs based on the provided array of parameter
    # specification hashes.
    def self.new_list(spec_list)
      spec_list.map { |spec| new(spec) }
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
      elsif spec_list.count { |spec| spec['name'] == '...' }.zero?
        spec_list.map { |spec| normalize_spec_hash(spec) }
      else
        error_msg = "'...' may not be the only parameter"
        raise(InvalidSpecKey, error_msg) if spec_list.count == 1

        i = spec_list.find_index { |spec| spec['name'] == '...' }
        var = spec_list[i]

        spec_list
          .reject { |spec| spec['name'] == '...' }
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
      Comment.validate_doc(spec['doc']) if spec.key?('doc')
      spec['includes'] = Wrapture.normalize_includes(spec['includes'])

      spec['type'] = '...' if spec['name'] == '...'

      unless spec.key?('type')
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

    # The type of the parameter.
    attr_reader :type

    # Creates a parameter specification based on the provided hash spec.
    def initialize(spec)
      @spec = ParamSpec.normalize_spec_hash(spec)
      @type = TypeSpec.new(@spec['type'])
    end

    # A Comment holding the parameter documentation.
    def doc
      if @spec.key?('doc')
        Comment.new("@param #{@spec['name']} #{@spec['doc']}")
      else
        Comment.new
      end
    end

    # A list of includes needed for this parameter.
    def includes
      @spec['includes']
    end

    # The name of the parameter.
    def name
      @spec['name']
    end

    # The parameter type and name, suitable for use in a function signature or
    # declaration. +owner+ must be the FunctionSpec that the parameter belongs
    # to.
    def signature(owner)
      @type.absolute(owner).variable(name)
    end

    # True if this parameter is variadic (the name is equal to '...').
    def variadic?
      @type.variadic?
    end
  end
end
