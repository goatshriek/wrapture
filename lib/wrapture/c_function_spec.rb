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

module Wrapture
  # A description of a C function.
  class CFunctionSpec
    # Returns a normalized copy of a hash specification of a class. See
    # normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec, *templates)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)), *templates)
    end

    # Normalizes a hash specification of a wrapped function. Normalization will
    # check for things like invalid keys, duplicate entries in include lists,
    # and will set missing keys to their default values (for example, an empty
    # list if no includes are given).
    def self.normalize_spec_hash!(spec)
      spec[:params] ||= []
      spec[:params] = spec[:params].map do |param_spec|
        if param_spec.is_a?(String)
          { value: param_spec }
        else
          param_spec[:value] = param_spec[:name] unless param_spec.key?(:value)
          param_spec
        end
      end

      spec[:includes] = Wrapture.normalize_array(spec[:includes])
      spec[:libraries] = Wrapture.normalize_array(spec[:libraries])

      spec[:error_check] ||= {}
      spec[:error_check][:rules] ||= []

      spec[:return] = { type: 'void' } unless spec.key?(:return)

      spec
    end

    # The error action for the wrapped function.
    attr_reader :error_action

    # The list of error rules for the wrapped function.
    attr_reader :error_rules

    # Creates a wrapped function spec based on the provided spec.
    #
    # The hash must have the following keys:
    # name:: the name of the wrapped function
    # params:: a list of parameters to supply when calling
    #
    # Each member of the params list must be either a string or a hash. A hash
    # must have a key of either (or both) 'name' and 'value'. If the value is a
    # string, then it is equivalent to a hash with the value key set to the
    # string. If only a 'name' key is provided, this will be used as the value.
    # A 'type' may be supplied as well, and is necessary if an equivalent struct
    # or pointer is to be supplied as the value so that casting can be performed
    # correctly.
    #
    # The following keys are optional:
    # includes:: A list of includes needed for this function.
    # libraries:: A list of libraries that must be linked to use this function.
    # return:: A type specification describing what the function returns. This
    # is assumed to be 'void' if missing.
    def initialize(spec)
      @spec = self.class.normalize_spec_hash(spec)

      check = @spec[:error_check]

      @error_rules = check[:rules].map do |rule_spec|
        RuleSpec.new(rule_spec)
      end

      action = check[:error_action]
      @error_action = ActionSpec.new(action) unless @error_rules.empty?
    end

    # Generates a function call from a provided wrapper. Parameters and
    # types are resolved using this wrapper's context.
    def call_from(wrapper)
      resolved_params = @spec[:params].map do |param|
        wrapper.resolve_param(param)
      end

      "#{@spec[:name]}( #{resolved_params.join(', ')} )"
    end

    # True if the wrapped function has an error check associated with it.
    def error_check?
      !@error_rules.empty?
    end

    # An array of includes required for this function call.
    def includes
      includes = @spec[:includes].dup

      includes.concat(@error_action.includes) if error_check?

      includes
    end

    # The name of the function.
    def name
      @spec[:name]
    end

    # An array of libraries required for this function call.
    def libraries
      @spec[:libraries].dup
    end

    # The parameters for this function.
    def params
      @spec[:params].dup
    end

    # A TypeSpec describing the type of the return value.
    #
    # Changed in release 0.4.2 to return a TypeSpec instead of a String.
    def return_val_type
      TypeSpec.new(@spec[:return][:type])
    end

    # True if calling this wrapped function needs to save/use the return value
    # for error checking. This is equivalent to checking all error rules for the
    # use of RETURN_VALUE_KEYWORD.
    #
    # This method was added in release 0.4.2.
    def use_return?
      @error_rules.any?(&:use_return?)
    end
  end
end
