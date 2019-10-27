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
  # A condition (or set of conditions) that a struct or its members must meet
  # in order to conform to a given specification. This allows a single struct
  # type to be equivalent to some class specifications, but not others.
  class RuleSpec
    # Normalizes a hash specification of a rule. Normalization checks for
    # invalid keys and unrecognized conditions.
    def self.normalize_spec_hash(spec)
      required_keys = %w[member-name condition value]

      missing_keys = required_keys - spec.keys
      unless missing_keys.empty?
        missing_msg = "required keys are missing: #{missing_keys.join(', ')}"
        raise InvalidSpecKey, missing_msg
      end

      extra_keys = spec.keys - required_keys
      unless extra_keys.empty?
        extra_msg = "these keys are unrecognized: #{extra_keys.join(', ')}"
        raise InvalidSpecKey, extra_msg
      end

      # TODO: check for unrecognized conditions
    end
  end
end
