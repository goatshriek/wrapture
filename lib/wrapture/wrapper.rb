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

require 'wrapture/wrapper/c_to_cpp'
require 'wrapture/wrapper/c_to_python'

module Wrapture
  # +Wrapper+ is the base wrapping functionality that all language wrappers
  # provide. All wrappers extend this module in order to interface with
  # universal Wrapture functionality like wrapper chaining.
  #
  # Wrapper modules must have a name of the format "SourceToDest" where Source
  # and Dest are the names of the input and output languages, respectively. This
  # name is used to determine the source and destination language symbols and
  # map which wrappers are compatible with build systems and other wrappers.
  #
  # This module expects the following functions to be implemented:
  # +self.wrap_class+
  # +self.wrap_enum+
  # +self.wrap_scope+
  module Wrapper
    # The symbol of the programming language this module's wrappers use as
    # input.
    def from_language
      name.split('::').last.split('To').first.downcase.to_sym
    end

    # The symbol of the programming language this module's wrappers generate as
    # output.
    def to_language
      name.split('::').last.split('To').last.downcase.to_sym
    end

    # Generates a wrapper for a given spec.
    def wrap(spec)
      case spec
      when ClassSpec
        wrap_class(spec)
      when EnumSpec
        wrap_enum(spec)
      when Scope
        wrap_scope(spec)
      end
    end
  end

  # An array of supported wrapper modules. Each of these extends the
  # +Wrapper+ module.
  WRAPPERS = [Wrapper::CToCpp, Wrapper::CToPython].freeze

  # An array of wrapper paths that wrap one language in another.
  #
  # +from+ and +to+ can be used to restrict the set of returned paths to the
  # provided source and destination languages. If provided, they should be a
  # symbol matching the value of the +FROM_LANGUAGE+ or +TO_LANGUAGE+ values on
  # +Wrapper+ modules (for example +:cpp+ or +:python+). Each of these may also
  # be an array of symbols to get more than one set of languages on either end,
  # for example <code>%i[c cpp]</code>.
  def self.paths(from: nil, to: nil, modules: WRAPPERS)
    from = case from
           when Symbol
             [from]
           when nil
             modules.map(&:from_language).uniq if from.nil?
           else
             from
           end

    to = case to
         when Symbol
           [to]
         when nil
           modules.map(&:to_language).uniq if to.nil?
         else
           to
         end

    # start with all modules that meet the starting criteria
    paths = modules.select do |it|
      from.include?(it.from_language)
    end
    paths = paths.map { |it| [it] }

    # add new paths that extend the last round's paths
    # until no new paths are found
    prev_paths = paths
    until prev_paths.empty?
      new_paths = []
      prev_paths.each do |path|
        modules.reject { |it| path.include?(it) }.each do |wrapper|
          if wrapper.from_language == path.last.to_language
            new_paths.append(path + [wrapper])
          end
        end
      end

      paths.concat(new_paths)
      prev_paths = new_paths
    end

    # remove the paths that do not meet the ending critera
    paths = paths.select { |it| to.include?(it.last.to_language) }

    paths.map { |path| Path.new(path) }
  end
end
