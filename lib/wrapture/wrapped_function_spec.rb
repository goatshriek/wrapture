# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2020 Joel E. Anderson
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
  # A description of a function to be wrapped by another language.
  class WrappedFunctionSpec
    # Normalizes a hash specification of a wrapped function. Normalization will
    # check for things like invalid keys, duplicate entries in include lists,
    # and will set missing keys to their default values (for example, an empty
    # list if no includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      normalized['params'] ||= []
      normalized['params'].each do |param_spec|
        param_spec['value'] = param_spec['name'] if param_spec['value'].nil?
      end

      normalized['includes'] = Wrapture.normalize_includes(spec['includes'])

      normalized['error-check'] ||= {}
      normalized['error-check']['rules'] ||= []

      unless spec.key?('return')
        normalized['return'] = {}
        normalized['return']['type'] = 'void'
      end

      normalized
    end

    # Creates a wrapped function spec based on the provided spec.
    #
    # The hash must have the following keys:
    # name:: the name of the wrapped function
    # params:: a list of parameters to supply when calling
    #
    # Each member of the params list must be a hash, with a mandatory key of
    # 'value' holding the value to be supplied as the parameter. If only a
    # 'name' key is provided, this will be used as the value. A 'type' may be
    # supplied as well, and is necessary if an equivalent struct or pointer is
    # to be supplied as the value so that casting can be performed correctly.
    #
    # The following key is optional:
    # includes:: a list of includes needed for this function
    def initialize(spec)
      @spec = self.class.normalize_spec_hash(spec)

      check = @spec['error-check']

      @error_rules = check['rules'].map do |rule_spec|
        RuleSpec.new(rule_spec)
      end

      action = check['error-action']
      @error_action = ActionSpec.new(action) unless @error_rules.empty?
    end

    # Generates a function call from a provided FunctionSpec. Paremeters and
    # types are resolved using this function's context.
    def call_from(function_spec)
      resolved_params = []

      @spec['params'].each do |param|
        resolved_params << function_spec.resolve_wrapped_param(param)
      end

      "#{@spec['name']}( #{resolved_params.join(', ')} )"
    end

    # Yields each line of the error check and any actions taken for this wrapped
    # function. If this function does not have any error check defined, then
    # this function returns without yielding anything.
    #
    # +return_val+ is used as the replacement for a return value signified by
    # the use of RETURN_VALUE_KEYWORD in the spec. If not specified it defaults
    # to +'return_val'+. This parameter was added in release 0.4.2.
    def error_check(return_val: 'return_val')
      return if @error_rules.empty?

      checks = @error_rules.map { |rule| rule.check(return_val: return_val) }
      yield "if( #{checks.join(' && ')} ){"
      yield "  #{@error_action.take};"
      yield '}'
    end

    # True if the wrapped function has an error check associated with it.
    def error_check?
      !@error_rules.empty?
    end

    # A list of includes required for this function call.
    def includes
      includes = @spec['includes'].dup

      includes.concat(@error_action.includes) if error_check?

      includes
    end

    # A TypeSpec describing the type of the return value.
    #
    # Changed in release 0.4.2 to return a TypeSpec instead of a String.
    def return_val_type
      TypeSpec.new(@spec['return']['type'])
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
