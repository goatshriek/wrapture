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

    # The name in UpperCamelCase.
    def self.upper_camel_case_name(name_words)
      name_words.map(&:capitalize).join
    end

    # Checks +name+ to see if it can be used in Named.words_from_name. Raises
    # InvalidName if not.
    def self.validate(name)
      if name.nil?
        raise InvalidName, 'names may not be nil'
      elsif name.is_a?(Enumerable)
        unless name.all? { |it| it.respond_to?(:to_str) }
          raise InvalidName,
                'all elements in an Enumerable name must respond to to_str'
        end
        if name.all? { |it| it.to_str.empty? }
          raise InvalidName, 'names may not be empty'
        end
      elsif !name.respond_to?(:to_str)
        raise InvalidName, 'names must be Enumerable or respond to to_str'
      elsif name.to_str.empty?
        raise InvalidName, 'names may not be empty'
      end
    end

    # Splits +name+ into an Array of words.
    def self.words_from_name(name)
      validate(name)

      case name
      when Enumerable
        name.map(&:to_str).map(&:downcase)
      when /^[a-z0-9]+$/
        [name.to_str]
      when /^[A-Z0-9]+$/
        [name.to_str.downcase]
      when /[a-zA-Z0-9]+(_[a-zA-Z0-9]+)+/
        name.to_str.split('_').map(&:downcase)
      else
        # match all CamelCase strings, including preceding capital letters
        # if the start is a lowercase word, this will be the first part
        name.to_str.scan(/[A-Z]*[^A-Z]*/).flat_map do |s|
          # next, split out the preceding capital letters, if any
          s.partition(/[A-Z][^A-Z]*$/)
        end.reject(&:empty?).map(&:downcase) # and finally, remove empty strings
      end
    end

    # The raw name, obtained by joining all parts.
    # TODO: remove
    def raw_name
      name_words.join
    end

    # The default name is the raw one.
    # TODO: removed
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
      Named.upper_camel_case_name(name_words)
    end
  end
end
