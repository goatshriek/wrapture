# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021-2026 Joel E. Anderson
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
  # Methods useful for named items such as specs.
  #
  # This module expects that +name_words+ gives an enumerable of parts that make
  # up the name. These words are used to make the name forms that this module
  # provides.
  module Named
    # The name in snake_case.
    def self.snake_case_name(name_words)
      name_words.map(&:downcase).join('_')
    end

    # Attempts to split a given name into its words.
    def self.words_from_name(name)
      case name
      when nil
        []
      when /^[a-z0-9]+$/
        [name]
      when /^[A-Z0-9]+$/
        [name.downcase]
      when /[a-zA-Z0-9]+(_[a-zA-Z0-9]+)+/
        name.split('_').map(&:downcase)
      else
        # match all CamelCase strings, including preceding capital letters
        # if the start is a lowercase word, this will be the first part
        name.scan(/[A-Z]*[^A-Z]*/).flat_map do |s|
          # next, split out the preceding capital letters, if any
          s.partition(/[A-Z][^A-Z]*$/)
        end.reject(&:empty?).map(&:downcase) # and finally, remove empty strings
      end
    end

    # The raw name, obtained by joining all parts.
    def raw_name
      name_words.join
    end

    # The default name is the raw one.
    alias name raw_name

    # The name in SCREAMING_SNAKE_CASE.
    def screaming_snake_case_name
      name_words.map(&:upcase).join('_')
    end

    # The name in snake_case.
    def snake_case_name
      Named.snake_case_name(name_words)
    end

    # The name in UpperCamelCase.
    def upper_camel_case_name
      name_words.map(&:capitalize).join
    end
  end
end
