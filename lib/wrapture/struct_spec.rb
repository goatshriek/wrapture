# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2023 Joel E. Anderson
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
  # A description of a struct.
  class StructSpec
    # Normalizes a hash specification of a struct. Normalization will check for
    # things like invalid keys, duplicate entries in include lists, and will set
    # missing keys to their default value (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup
      normalized.default = []

      normalized['includes'] = Wrapture.normalize_array(spec['includes'])

      normalized['members'] ||= []

      normalized
    end

    # A list of rules defined for this struct.
    attr_reader :rules

    # Creates a struct spec based on the provided spec hash.
    #
    # The hash must have the following keys:
    # name:: the name of the struct
    #
    # The following keys are optional:
    # includes:: a list of includes required for the struct
    # members:: a list of the members of the struct, each with a type and name
    # field
    # rules:: a list of conditions this struct and its members must meet (refer
    # to the RuleSpec class for more details)
    def initialize(spec)
      @spec = StructSpec.normalize_spec_hash(spec)

      @rules = @spec['rules'].map { |rule_spec| RuleSpec.new(rule_spec) }
    end

    # A declaration of the struct with the given variable name.
    def declaration(name)
      "struct #{@spec['name']} #{name}"
    end

    # A list of includes required for this struct.
    def includes
      @spec['includes'].dup
    end

    # A string containing the typed members of the struct, separated by commas.
    def member_list
      members = @spec['members'].map do |member|
        TypeSpec.new(member['type']).variable(member['name'])
      end

      members.join ', '
    end

    # A string containing the typed members of the struct, with their default
    # values if provided, separated by commas.
    def member_list_with_defaults
      @spec['members'].map do |member|
        member_str = TypeSpec.new(member['type']).variable(member['name'])

        if member.key?('default-value')
          default_value = member['default-value']

          member_str += ' = '
          member_str += if member['type'] == 'const char *'
                          "\"#{default_value}\""
                        elsif member['type'].end_with?('char')
                          "'#{default_value}'"
                        else
                          default_value.to_s
                        end
        end

        member_str
      end.join(', ')
    end

    # The members of the struct
    def members
      @spec['members']
    end

    # True if there are members included in the struct specification.
    def members?
      !@spec['members'].empty?
    end

    # The name of this struct
    def name
      @spec['name']
    end

    # A declaration of a pointer to the struct with the given variable name.
    def pointer_declaration(name)
      "struct #{@spec['name']} *#{name}"
    end

    # A string containing an expression that returns true if the struct with
    # the given name meets all rules defined for this struct.
    def rules_check(name)
      @rules.map { |rule| rule.check(variable: name) }.join(' && ')
    end
  end
end
