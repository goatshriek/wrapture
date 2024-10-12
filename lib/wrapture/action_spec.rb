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

module Wrapture
  # An action to take within a generated program.
  class ActionSpec
    # Normalizes a hash specification of a rule. Normalization checks for
    # invalid keys and unrecognized conditions.
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      required_keys = %w[name type]

      missing_keys = required_keys - spec.keys
      unless missing_keys.empty?
        missing_msg = "required keys are missing: #{missing_keys.join(', ')}"
        raise(MissingSpecKey, missing_msg)
      end

      unless spec.include?('wrapped-function') || spec.include?('value')
        extra_msg = 'either wrapped-function or value must be present'
        raise(MissingSpecKey, extra_msg)
      end

      if spec.include?('wrapped-function') && spec.include?('value')
        extra_msg = 'wrapped-function and value cannot both be present'
        raise(KeyConflict, extra_msg)
      end

      if spec.include?('wrapped-function')
        wrap = WrappedFunctionSpec.normalize_spec_hash(spec['wrapped-function'])
        normalized['wrapped-function'] = wrap
      end

      normalized
    end

    # Creates an action spec based on the provided spec hash.
    #
    # The hash must have the following keys:
    # name:: the type of action to take (currently only throw-exception is
    # supported)
    # type:: the type of the exception thrown
    #
    # One of these two keys must be present, but not both:
    # value:: the value to use to create the exception
    # wrapped-function:: a function to use to create the exception, described
    # as a wrapped function call. If the name of the constructor is left out,
    # then the wrapped function is assumed to be a constructor for the provided
    # type.
    def initialize(spec)
      @spec = ActionSpec.normalize_spec_hash(spec)
    end

    # A list of includes needed for the action.
    def includes
      if @spec.include?('wrapped-function')
        @spec['wrapped-function']['includes'].dup
      else
        []
      end
    end

    # The type of exception.
    def type
      TypeSpec.new(@spec['type'])
    end

    # The value of the action, if one is set.
    def value
      @spec.fetch('value', nil)
    end

    # True if this spec has a value defined.
    def value?
      @spec.include?('value')
    end
  end
end
