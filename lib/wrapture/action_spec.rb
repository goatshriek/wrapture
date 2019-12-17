# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019 Joel E. Anderson
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

require 'wrapture/errors'

module Wrapture
  # An action to take within a generated program.
  class ActionSpec
    # Normalizes a hash specification of a rule. Normalization checks for
    # invalid keys and unrecognized conditions.
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      required_keys = %w[name constructor]

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

      normalized
    end

    # Creates an action spec based on the provided spec hash.
    #
    # The hash must have the following keys:
    # name:: the type of action to take (currently only throw-exception is
    # supported)
    # constructor:: the function to use to create the exception, described as a
    # wrapped function call
    def initialize(spec)
      @spec = ActionSpec.normalize_spec_hash(spec)
    end
  end
 end
