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
  # A condition (or set of conditions) that a struct or its members must meet
  # in order to conform to a given specification. This allows a single struct
  # type to be equivalent to some class specifications, but not others.
  class RuleSpec
    # A map of condition strings to their operators.
    CONDITIONS = { 'equals' => '==',
                   'greater-than' => '>',
                   'greater-than-equal' => '>=',
                   'less-than' => '<',
                   'less-than-equal' => '<=',
                   'not-equals' => '!=' }.freeze

    # Normalizes a hash specification of a rule. Normalization checks for
    # invalid keys and unrecognized conditions.
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      required_keys = if spec.key?('member-name')
                        normalized['type'] = 'struct-member'
                        %w[member-name condition value].freeze
                      else
                        normalized['type'] = 'expression'
                        %w[left-expression condition right-expression].freeze
                      end

      missing_keys = required_keys - spec.keys
      unless missing_keys.empty?
        missing_msg = "required keys are missing: #{missing_keys.join(', ')}"
        raise(MissingSpecKey, missing_msg)
      end

      extra_keys = spec.keys - required_keys
      unless extra_keys.empty?
        extra_msg = "these keys are unrecognized: #{extra_keys.join(', ')}"
        raise(InvalidSpecKey, extra_msg)
      end

      unless RuleSpec::CONDITIONS.keys.include?(spec['condition'])
        condition_msg = "#{spec['condition']} is an invalid condition"
        raise(InvalidSpecKey, condition_msg)
      end

      normalized
    end

    # Creates a rule spec based on the provided spec. Rules may be one of a
    # number of different varieties.
    #
    # Available conditions are available in the RuleSpec::CONDITIONS map, with
    # the mapped values being the operate each one translates to.
    #
    # For a rule that checks a struct member against a given value (a
    # +struct-member+ rule):
    # member-name:: the name of the struct member the rule applies to
    # condition:: the condition this rule uses
    # value:: the value to use in the condition check
    #
    # For a rule that compares two expressions against one another (an
    # +expression+ rule):
    # left-expression:: the left expression in the comparison
    # condition:: the condition this rule uses
    # right-expression:: the right expression in the comparison
    def initialize(spec)
      @spec = RuleSpec.normalize_spec_hash(spec)
    end

    # A string containing a check for a struct of the given name for this rule.
    #
    # +variable+ can be provided to provide the variable holding a struct
    # pointer for +struct-member+ rules.
    #
    # +return_val+ is used as the replacement for a return value signified by
    # the use of RETURN_VALUE_KEYWORD in the spec. If not specified it defaults
    # to +'return_val'+. This parameter was added in release 0.4.2.
    def check(variable: nil, return_val: 'return_val')
      condition = RuleSpec::CONDITIONS[@spec['condition']]

      if @spec['type'] == 'struct-member'
        "#{variable}->#{@spec['member-name']} #{condition} #{@spec['value']}"
      else
        left = @spec['left-expression']
        right = @spec['right-expression']
        "#{left} #{condition} #{right}".sub(RETURN_VALUE_KEYWORD, return_val)
      end
    end

    # True if this rule requires a return value. This is equivalent to checking
    # for the presence of RETURN_VALUE_KEYWORD in any of the expressions.
    #
    # This method was added in release 0.4.2.
    def use_return?
      @spec['type'] == 'expression' &&
        [@spec['left-expression'],
         @spec['right-expression']].include?(RETURN_VALUE_KEYWORD)
    end
  end
end
