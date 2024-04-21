# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021-2023 Joel E. Anderson
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
  # A description of code to be wrapped by another language.
  class WrappedCodeSpec
    # Returns a normalized copy of a hash specification of wrapped code. See
    # normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of wrapped code in place. Normalization
    # will check for things like invalid keys, duplicate entries in include
    # lists, and will set missing keys to their default values (for example, an
    # empty list if no includes are given).
    def self.normalize_spec_hash!(spec)
      spec['includes'] = Wrapture.normalize_array(spec['includes'])
      spec['libraries'] = Wrapture.normalize_array(spec['libraries'])

      spec['error-check'] ||= {}
      spec['error-check']['rules'] ||= []

      unless spec.key?('return')
        spec['return'] = {}
        spec['return']['type'] = 'void'
      end

      spec
    end

    # Creates a wrapped code spec based on the provided spec.
    #
    # The hash must have the following keys:
    # lines:: a list of lines of code
    #
    # The following keys are optional:
    # includes:: A list of includes needed for this code.
    # libraries:: A list of libraries that must be linked to use this code.
    # return:: A type specification describing the type of the return value
    # variable. If missing, no return value is assumed.
    def initialize(spec)
      @spec = self.class.normalize_spec_hash(spec)

      check = @spec['error-check']

      @error_rules = check['rules'].map do |rule_spec|
        RuleSpec.new(rule_spec)
      end

      action = check['error-action']
      @error_action = ActionSpec.new(action) unless @error_rules.empty?
    end

    # Yields each line of the error check and any actions taken for this code.
    # If this code does not have any error check defined, then this function
    # returns without yielding anything.
    #
    # +return_val+ is used as the replacement for a return value signified by
    # the use of RETURN_VALUE_KEYWORD in the spec. If not specified it defaults
    # to +'return_val'+.
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

    # An array of libraries required for this code.
    def libraries
      @spec['libraries'].dup
    end

    # A list of the lines of code wrapped.
    def lines
      @spec['lines']
    end

    # A TypeSpec describing the type of the return value.
    def return_val_type
      TypeSpec.new(@spec['return']['type'])
    end

    # True if calling this wrapped code provides a return value variable.
    def use_return?
      @spec['return']['type'] != 'void'
    end
  end
end
