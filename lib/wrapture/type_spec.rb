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
  # A description of a type used in a specification.
  class TypeSpec
    # Returns a normalized copy of the hash specification of a type in +spec+.
    # See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes the hash specification of a type in +spec+ in place. This will
    # normalize the include list.
    def self.normalize_spec_hash!(spec)
      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec
    end

    # Creates a parameter specification based on the provided hash +spec+.
    # +spec+ can be a string instead of a hash, in which case it will be used
    # as the name of the type.
    def initialize(spec)
      @spec = if spec.nil?
                { 'name' => 'void' }
              elsif spec.is_a?(String)
                { 'name' => spec }
              else
                TypeSpec.normalize_spec_hash(spec)
              end
    end

    # True if this type is an equivalent struct pointer reference.
    def equivalent_pointer?
      @spec['name'] == EQUIVALENT_POINTER_KEYWORD
    end

    # True if this type is an equivalent struct reference.
    def equivalent_struct?
      @spec['name'] == EQUIVALENT_STRUCT_KEYWORD
    end

    # A list of includes needed for this type.
    def includes
      @spec['includes']
    end

    # The name of the type.
    def name
      @spec['name']
    end

    # True if this type is a pointer.
    def pointer?
      @spec['name'].end_with?('*')
    end

    # True if this type is a reference to a class instance.
    def self?
      @spec['name'] == SELF_REFERENCE_KEYWORD
    end

    # A string with a declaration of a variable named +name+ of this type.
    def variable(name)
      "#{@spec['name']}#{' ' unless @spec['name'].end_with?('*')}#{name}"
    end
  end
end
