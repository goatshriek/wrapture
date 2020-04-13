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
  # A description of an enumeration.
  class EnumSpec
    # Returns a normalized copy of a hash specification of an enumeration in
    # place. See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of an enumeration in place. Normalization
    # will remove duplicate entries in include lists.
    def self.normalize_spec_hash!(spec)
      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec
    end

    # Creates an enumeration specification based on the provided hash spec.
    def initialize(spec)
      @spec = EnumSpec.normalize_spec_hash(spec)
    end

    # The name of the enumeration.
    def name
      @spec['name']
    end
  end
end
