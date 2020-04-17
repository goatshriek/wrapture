# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2020 Joel E. Anderson
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

require 'wrapture/comment'
require 'wrapture/normalize'

module Wrapture
  # A description of a constant.
  class ConstantSpec
    # Normalizes a hash specification of a constant. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and
    # will set missing keys to their default value (for example, an empty list
    # if no includes are given).
    def self.normalize_spec_hash(spec)
      Comment.validate_doc(spec['doc']) if spec.key?('doc')

      normalized = spec.dup

      normalized['version'] = Wrapture.spec_version(spec)
      normalized['includes'] = Wrapture.normalize_includes spec['includes']

      normalized
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
      @doc = @spec.key?('doc') ? Comment.new(@spec['doc']) : nil
      @type = TypeSpec.new(@spec['type'])
    end

    # A list of includes needed for the declaration of this constant.
    def declaration_includes
      @spec['includes'].dup
    end

    # A list of includes needed for the definition of this constant.
    def definition_includes
      @spec['includes'].dup
    end

    # Yields each line of the declaration of this constant, including any
    # documentation.
    def declaration
      @doc&.format_as_doxygen(max_line_length: 76) { |line| yield line }
      yield "static const #{@type.variable(@spec['name'])};"
    end

    # The definition of this constant.
    def definition(class_name)
      expanded_name = "#{class_name}::#{@spec['name']}"
      "const #{@spec['type']} #{expanded_name} = #{@spec['value']}"
    end
  end
end
