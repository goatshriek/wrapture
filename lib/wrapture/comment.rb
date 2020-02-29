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
    def format(first_line: '', last_line: '')
      yield first_line
      yield @text
      yield last_line
    end
  end
end
