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
    # will remove duplicate entries in include lists and check for a name key.
    def self.normalize_spec_hash!(spec)
      unless spec.key?('name')
        raise MissingSpecKey, 'a name is required for enumerations'
      end

      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec
    end

    # Creates an enumeration specification based on the provided hash spec.
    def initialize(spec)
      @spec = EnumSpec.normalize_spec_hash(spec)
    end

    # Generates the wrapper definition file.
    def generate_wrapper
      filename = "#{@spec['name']}.hpp"

      File.open(filename, 'w') do |file|
        definition_contents do |line|
          file.puts(line)
        end
      end

      [filename]
    end

    # The name of the enumeration.
    def name
      @spec['name']
    end

    private

    # Yields each line of the definition of the wrapper for this enum.
    def definition_contents
      yield "enum class #{name} {"

      @spec['elements'][0...-1].each do |element|
        yield "  #{element_definition(element)},"
      end

      yield "  #{element_definition(@spec['elements'].last)}"

      yield '};'
    end

    # Gives the definition of en element spec.
    def element_definition(element)
      if element.key?('value')
        "#{element['name']} = #{element['value']}"
      else
        element['name']
      end
    end
  end
end
