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
  # A description of a parameter used in a generated function.
  class ParamSpec
    # Returns a list of new ParamSpecs based on the provided array of parameter
    # specification hashes.
    def self.new_list(spec_list)
      spec_list.map { |spec| new(spec) }
    end

    # Returns a normalized copy of a list of parameter hash specifications in
    # place.
    def self.normalize_param_list(spec_list)
      if spec_list.nil?
        []
      else
        spec_list.map { |spec| normalize_spec_hash(spec) }
      end
    end

    # Returns a normalized copy of a hash specification of a parameter.
    # Normalization will remove duplicate entries from include lists and
    # validate key values.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of a parameter in place. See
    # normalize_spec_hash for details.
    def self.normalize_spec_hash!(spec)
      Comment.validate_doc(spec['doc']) if spec.key?('doc')
      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec
    end

    # Creates a parameter specification based on the provided hash spec.
    def initialize(spec)
      @spec = ParamSpec.normalize_spec_hash(spec)
    end

    # A Comment holding the parameter documentation.
    def doc
      if @spec.key?('doc')
        Comment.new("@param #{@spec['name']} #{@spec['doc']}")
      else
        Comment.new
      end
    end

    # A list of includes needed for this parameter.
    def includes
      @spec['includes']
    end
  end
end
