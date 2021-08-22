# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020-2021 Joel E. Anderson
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
    # will remove duplicate entries in include lists and check for a name key.
    def self.normalize_spec_hash!(spec)
      unless spec.key?('name')
        raise MissingSpecKey, 'a name is required for enumerations'
      end

      if spec.key?('elements')
        unless spec['elements'].is_a?(Array)
          raise InvalidSpecKey, 'the elements key must be an array'
        end
      else
        raise MissingSpecKey, 'elements are required for enumerations'
      end

      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec['elements'].each do |element|
        element['includes'] = Wrapture.normalize_includes(element['includes'])
      end

      spec
    end

    # Creates an enumeration specification based on the provided hash spec.
    def initialize(spec)
      @spec = EnumSpec.normalize_spec_hash(spec)
      @doc = Comment.new(@spec.fetch('doc', nil))
    end

    # The documentation of the enumeration.
    attr_reader :doc

    # A list of the includes needed for the definition of the enumeration.
    def definition_includes
      includes = @spec['includes'].dup

      @spec['elements'].each do |element|
        includes.concat(element['includes'])
      end

      includes.uniq
    end

    # A list of elements in this enumeration.
    # This should be redefined as a separate type of spec in the long run
    # instead of being raw hashes.
    def elements
      @spec['elements']
    end

    # The name of the enumeration.
    def name
      @spec['name']
    end

    # The namespace of the enumeration, or nil if it does not have one.
    def namespace
      @spec.fetch('namespace', nil)
    end

    # True if the enumeration has a namespace, false if not.
    def namespace?
      @spec.key?('namespace')
    end
  end
end
