# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025-2026 Joel E. Anderson
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
  module CSource
    # An include directive for C source files.
    class CInclude
      # A comment associated with the include.
      attr_reader :comment

      # The file the include specifies.
      attr_reader :file

      # Whether or not double quotes are used for this include.
      attr_reader :quote

      # Creates an include for the given filename.
      def initialize(file, comment: Comment.new, quote: false)
        @comment = case comment
                   when String
                     Comment.new(comment)
                   else
                     comment
                   end
        @file = file
        @quote = quote
      end
    end
  end
end
