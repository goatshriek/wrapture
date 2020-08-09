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
  # A comment that can be inserted in generated source code.
  #
  # Comments are primarily used to insert documentation about generated code for
  # documentation generation tools such as Doxygen.
  class Comment
    # Validates a doc string.
    def self.validate_doc(doc)
      raise InvalidDoc, 'a doc must be a string' unless doc.is_a?(String)
    end

    # The raw text of the comment.
    attr_reader :text

    # Creates a comment from a string. If the provided string is nil, then an
    # empty string is used.
    def initialize(comment = '')
      @text = comment.nil? ? '' : comment
    end

    # True if this comment is empty, false otherwise.
    def empty?
      @text.empty?
    end

    # Yields each line of the comment formatted as specified.
    def format(line_prefix: '// ', first_line: nil, last_line: nil,
               max_line_length: 80)
      return if @text.empty?

      yield first_line if first_line

      paragraphs(max_line_length - line_prefix.length) do |line|
        yield "#{line_prefix}#{line}".rstrip
      end

      yield last_line if last_line
    end

    # Calls the given block for each line of the comment formatted using Doxygen
    # style.
    def format_as_doxygen(max_line_length: 80, &block)
      format(line_prefix: ' * ', first_line: '/**',
             last_line: ' */', max_line_length: max_line_length) do |line|
        block.call(line)
      end
    end

    private

    # Yields the comment converted into paragraph-style blocks.
    #
    # Consecutive lines with text are concatenated together to the maximum line
    # length, regardless of the original line length in the comment. One or more
    # empty lines are written as a single empty line, separating paragraphs.
    #
    # Yielded lines may have trailing spaces, which are not considered part of
    # the maximum length. The caller must strip these off.
    def paragraphs(line_length)
      running_line = String.new
      newline_mode = true
      @text.each_line do |line|
        if line.strip.empty?
          unless newline_mode
            yield running_line
            yield ''
            running_line.clear
            newline_mode = true
          end
        else
          newline_mode = false
        end

        line.scan(/\S+/) do |word|
          if running_line.length + word.length > line_length
            yield running_line
            running_line = String.new("#{word} ")
          else
            running_line << word << ' '
          end
        end
      end

      yield running_line
    end
  end
end
