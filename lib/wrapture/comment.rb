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
    # Creates a comment from a string.
    def initialize(comment)
      @text = comment
    end

    # Yields each line of the comment formatted as specified.
    def format(line_prefix: '// ', first_line: nil, last_line: nil,
               max_line_length: 80)
      yield first_line if first_line

      running_line = line_prefix.dup
      newline_mode = false
      @text.each_line do |line|
        if line.strip.empty?
          if !newline_mode
            yield running_line.rstrip
            yield line_prefix.rstrip
            running_line = line_prefix.dup
            newline_mode = true
          end
        else
          newline_mode = false
        end

        line.scan(/\S+/) do |word|
          if running_line.length + word.length > max_line_length
            yield running_line.rstrip
            running_line = line_prefix.dup + word + ' '
          else
            running_line << word << ' '
          end
        end
      end

      yield running_line.rstrip

      yield last_line if last_line
    end

    # Yields each line of the comment formatted using Doxygen style.
    def format_as_doxygen(max_line_length: 80)
      format(line_prefix: ' * ', first_line: '/**',
             last_line: ' */', max_line_length: max_line_length) do |line|
        yield line
      end
    end
  end
end
