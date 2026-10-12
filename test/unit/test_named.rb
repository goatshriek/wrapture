# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

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

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class NamedTest < Minitest::Test
  def test_validate_array_of_ints
    assert_raises(Wrapture::InvalidName) do
      Wrapture::Named.validate([1, 2, 3])
    end
  end

  def test_validate_array_of_empty_strings
    assert_raises(Wrapture::InvalidName) do
      Wrapture::Named.validate(['', '', ''])
    end
  end

  def test_validate_array_of_strings
    Wrapture::Named.validate(%w[one two three])
  end

  def test_validate_empty_string
    assert_raises(Wrapture::InvalidName) do
      Wrapture::Named.validate('')
    end
  end

  def test_validate_int
    assert_raises(Wrapture::InvalidName) do
      Wrapture::Named.validate(3)
    end
  end

  def test_validate_nil
    assert_raises(Wrapture::InvalidName) do
      Wrapture::Named.validate(nil)
    end
  end

  def test_validate_snake_case_string
    Wrapture::Named.validate('this_name_is_fine')
  end

  def test_words_from_lower_camel_case
    name = 'lowerCamelCaseName'
    words = Wrapture::Named.words_from_name(name)

    assert_equal(%w[lower camel case name], words)
  end

  def test_words_from_array
    words = Wrapture::Named.words_from_name(%w[LOTS oF Words])

    assert_equal(%w[lots of words], words)
  end

  def test_words_from_screaming_snake_case
    name = 'SCREAMING_SNAKE_CASE_NAME'
    words = Wrapture::Named.words_from_name(name)

    assert_equal(%w[screaming snake case name], words)
  end

  def test_words_from_single_lower_case_word
    words = Wrapture::Named.words_from_name('name')

    assert_equal(%w[name], words)
  end

  def test_words_from_single_screaming_case_word
    words = Wrapture::Named.words_from_name('NAME')

    assert_equal(%w[name], words)
  end

  def test_words_from_snake_case
    name = 'snake_case_name'
    words = Wrapture::Named.words_from_name(name)

    assert_equal(%w[snake case name], words)
  end

  def test_words_from_upper_camel_case
    name = 'UpperCamelCaseName'
    words = Wrapture::Named.words_from_name(name)

    assert_equal(%w[upper camel case name], words)
  end
end
