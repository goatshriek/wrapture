# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2023 Joel E. Anderson
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

require 'wrapture/named'

module Wrapture
  # A description of a constant.
  class ConstantSpec
    include Named

    # Returns a normalized copy of a hash specification of an enumeration.
    # See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of a constant.
    #
    # The version will be set to the current version of Wrapture if it is
    # missing.
    #
    # The include list will be an empty array if missing, and an array with
    # a single string if it is a string.
    def self.normalize_spec_hash!(spec)
      spec['doc'] = '' unless spec.key?('doc')
      Comment.validate_doc(spec['doc'])

      spec['version'] = Wrapture.spec_version(spec)
      spec['includes'] = Wrapture.normalize_array(spec['includes'])

      spec
    end

    # Creates a constant spec based on the provided hash spec
    #
    # The hash must have the following keys:
    # name:: the name of the constant
    # type:: the type of the constant
    # value:: the value to assign to the constant
    # includes::  a list of includes that need to be added in order for this
    # constant to be valid (for example, includes for the type and value).
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this constant
    def initialize(spec)
      @spec = ConstantSpec.normalize_spec_hash(spec)
      @doc = Comment.new(@spec['doc'])
      @type = TypeSpec.new(@spec['type'])
    end

    # The documentation comment for this constant.
    attr_reader :doc

    # The type of this constant.
    attr_reader :type

    # A list of includes needed for the declaration of this constant.
    def declaration_includes
      @spec['includes'].dup
    end

    # A list of includes needed for the definition of this constant.
    def definition_includes
      @spec['includes'].dup
    end

    # TODO declaration and definition need to be moved to c-specific code
    # Calls the given block once for each line of the declaration of this
    # constant, including any documentation.
    def declaration(&block)
      @doc&.format_as_doxygen(max_line_length: 76) { |line| block.call(line) }
      block.call("static const #{@type.variable(@spec['name'])};")
    end

    # The definition of this constant.
    def definition(class_name)
      expanded_name = "#{class_name}::#{@spec['name']}"
      "const #{@spec['type']} #{expanded_name} = #{@spec['value']}"
    end

    # The name of the constant.
    def name
      @spec['name']
    end

    # The value of the constant.
    def value
      @spec['value']
    end
  end
end
