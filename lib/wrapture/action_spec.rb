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

require 'wrapture/sourced'

module Wrapture
  # An action to take within a generated program.
  #
  # This is currently synonomous with raising an exception, but will likely be
  # expanded to other things in the future.
  class ActionSpec
    include Sourced

    # A hash with language-specific wrapping details.
    attr_reader :source

    # The type of the exception that will be thrown.
    attr_reader :type_spec

    # An expression with the value used to create the exception, or nil if no
    # value is needed.
    attr_accessor :value

    # Creates a new ActionSpec from +hash+.
    #
    # The hash must have the following keys:
    # name:: the type of action to take (currently only throw_exception is
    #        supported)
    # type:: the type of the exception thrown
    #
    # A +:value+ key may also be provided, which will be used to create the
    # the exception instance.
    def self.from_hash(hash)
      required_keys = %i[name type]
      optional_keys = %i[value source]

      extra_keys = hash.keys - required_keys - optional_keys
      unless extra_keys.empty?
        extra_msg = "these keys are unrecognized: #{extra_keys.join(', ')}"
        raise(InvalidSpecKey, extra_msg)
      end

      missing_keys = required_keys - hash.keys
      unless missing_keys.empty?
        missing_msg = "required keys are missing: #{missing_keys.join(', ')}"
        raise(MissingSpecKey, missing_msg)
      end

      spec = new(hash[:type])

      unless hash.dig(:source, :c).nil?
        spec.source[:c] = CSource::CFunction.from_hash(hash[:source][:c])
      end

      spec.value = hash[:value] if hash.key?(:value)

      spec
    end

    # Normalizes a hash specification of a rule. Normalization checks for
    # invalid keys and unrecognized conditions.
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      required_keys = %i[name type]
      optional_keys = %i[value source]

      extra_keys = spec.keys - required_keys - optional_keys
      unless extra_keys.empty?
        extra_msg = "these keys are unrecognized: #{extra_keys.join(', ')}"
        raise(InvalidSpecKey, extra_msg)
      end

      missing_keys = required_keys - spec.keys
      unless missing_keys.empty?
        missing_msg = "required keys are missing: #{missing_keys.join(', ')}"
        raise(MissingSpecKey, missing_msg)
      end

      normalized
    end

    # An action must have a +type_spec+ which describes the exception class that
    # is raised.
    def initialize(type_spec)
      @type_spec = if type_spec.is_a?(TypeSpec)
                     type_spec
                   else
                     TypeSpec.new(type_spec)
                   end
      @source = {}
      @value = nil
    end

    # True if this spec has a value defined.
    def value?
      !@value.nil?
    end
  end
end
