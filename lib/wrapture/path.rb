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
  # Paths represent a sequence of wrappers that go from a source language to a
  # target one. They allow wrappers to be chained together to go between
  # languges that don't have a direct wrapper implemented.
  class Path
    # Creates an array of modules from a string representation of a list of
    # languages. The string must be a comma-separated list of at least two
    # languages, for example 'c,cpp'.
    def self.wrappers_from_string(str)
      str.split(',').each_cons(2).map do |pair|
        from = pair[0].to_sym
        to = pair[1].to_sym

        WRAPPERS.find do |wrapper|
          wrapper.from_language == from && wrapper.to_language == to
        end
      end
    end

    # A path can be created either directly from an array of wrapper modules,
    # or from a string with a list of langauges to go through. See
    # Path::wrappers_from_string for the format of the string.
    def initialize(wrappers)
      case wrappers
      when String
        @wrappers = self.class.wrappers_from_string(wrappers)
      when Enumerable
        @wrappers = Array.new(wrappers)
      end
    end

    # The enumerable of wrappers this path contains.
    attr_reader :wrappers

    # Compares a path with another object.
    #
    # Path instances are equal to each other when their wrappers are the same.
    # A path will also be equal to an array of wrapper modules that is equal to
    # its own wrapper list.
    def ==(other)
      case other
      when Path
        @wrappers == other.wrappers
      when Array
        @wrappers == other
      else
        false
      end
    end
  end
end
