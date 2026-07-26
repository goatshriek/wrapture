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

require 'wrapture/wrapper/c'
require 'wrapture/wrapper/c_to_cpp'
require 'wrapture/wrapper/c_to_python'
require 'wrapture/wrapper/cpp'

module Wrapture
  # +Wrapper+ includes the base wrapping functionality that all language
  # wrappers provide. All wrappers extend this module in order to interface with
  # universal Wrapture functionality like wrapper chaining.
  #
  # Wrapper modules must have a name of the format "SourceToDest" where Source
  # and Dest are the names of the input and output languages, respectively. This
  # name is used to determine the source and destination language symbols and
  # map which wrappers are compatible with build systems and other wrappers.
  #
  # This module expects the following functions to be implemented:
  # +self.wrap_class_context+
  # +self.wrap_constant_context+
  # +self.wrap_enum_context+
  # +self.wrap_function_context+
  # +self.wrap_namespace_context+
  # Each of these must take a single Context instance as their argument, with
  # the root being of the named type, and return a SourceSet.
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

    # Generates a wrapper for +context+.
    def wrap(context, scope: nil)
      spec = if context.is_a?(Context)
               context.root
             else
               context
             end

      case spec
      when ClassSpec
        wrap_class(context, scope: scope)
      when ConstantSpec
        wrap_constant(context)
      when EnumSpec
        wrap_enum(context)
      when FunctionSpec
        wrap_function(context)
      when Namespace
        wrap_namespace(context)
      else
        wrap_name = 'Wrapture::Wrapper.wrap'
        raise InvalidSpec, "#{spec.class} not supported by #{wrap_name}"
      end
    end

    # Generates a wrapper for +class_spec+ in an empty Context. If +class_spec+
    # is a Context, then it is passed to wrap_class_context unchanged.
    def wrap_class(class_spec)
      context = if class_spec.is_a?(Context)
                  class_spec
                else
                  Context.new(class_spec)
                end
      wrap_class_context(context)
    end

    # Generates a wrapper for +constant_spec+ in an empty Context. If
    # +constant_spec+ is a Context, then it is passed to wrap_constant_context
    # unchanged.
    def wrap_constant(constant_spec)
      context = if constant_spec.is_a?(Context)
                  constant_spec
                else
                  Context.new(constant_spec)
                end
      wrap_constant_context(context)
    end

    # Generates a wrapper for +enum_spec+ in an empty Context. If +enum_spec+
    # is a Context, then it is passed to wrap_enum_context unchanged.
    def wrap_enum(enum_spec)
      context = if enum_spec.is_a?(Context)
                  enum_spec
                else
                  Context.new(enum_spec)
                end
      wrap_enum_context(context)
    end

    # Generates a wrapper for +func_spec+ in an empty Context. If +func_spec+
    # is a Context, then it is passed to wrap_func_context unchanged.
    def wrap_function(func_spec)
      context = if func_spec.is_a?(Context)
                  func_spec
                else
                  Context.new(func_spec)
                end
      wrap_function_context(context)
    end

    # Generates a wrapper for +namespace+ in an empty Context. If +namespace+
    # is a Context, then it is passed to wrap_namespace_context unchanged.
    def wrap_namespace(namespace)
      context = if namespace.is_a?(Context)
                  namespace
                else
                  Context.new(namespace)
                end
      wrap_namespace_context(context)
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
