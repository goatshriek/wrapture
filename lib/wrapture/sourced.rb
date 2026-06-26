# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2026 Joel E. Anderson
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
  # Specs that have a +source+ attribute can include the Sourced module to gain
  # lookup and resolution functions for the source language settings.
  #
  # The +source+ attribute must not be nil, and must be a Hash instance keyed by
  # language symbols. The exact contents of these keys may change depending on
  # the class. The +:base+ key must be a Hash if it exists, and may be used to
  # hold values that are used in cases where a specific language key does not
  # have a value set.
  module Sourced
    # True if the +:base+ key has an entry for the given key that is true.
    def base?(key)
      source.key?(:base) &&
        source[:base].key?(key) &&
        source[:base][key]
    end
  end
end
