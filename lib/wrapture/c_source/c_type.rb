# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025 Joel E. Anderson
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
    # A basic type used in C source code. Types that have additional handling or
    # features, such as struct or function types, have their own specialized
    # classes.
    class CType
      # Creates a type for the base type given.
      def initialize(base)
        @base = base
      end

      # Compares with another type.
      def ==(other)
        to_s == other.to_s
      end

      # Alias to support Enumerable#uniq.
      alias eql? ==

      # C source code representing the type.
      def to_s
        @base
      end
    end
  end
end
