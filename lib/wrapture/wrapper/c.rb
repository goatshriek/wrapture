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
  module Wrapper
    # Utilities for wrappers that use C as either a from or to language.
    module C
      # Makes a decorated version of the given name so that it is unique among
      # other wrapper names based on the C language. This is done by prepending
      # "c" to the name, for example "MyLib" will become "CMyLib".
      def self.decorate_name_words(name_words)
        ['c'] + name_words
      end

      # True if one of the ancestors of a class has an equivalent struct that
      # it can use.
      #
      # TODO: For now we only check the direct parent class. However,
      # once a context is formalized into a type, it should be changed
      # to that, and the entire chain should be checked.
      def self.equivalent_ancestor?(class_spec)
        return false unless class_spec.child?

        parent = class_spec.parent_spec
        !parent.nil? &&
          parent.wrapped.key?(:c) &&
          parent[:c] == class_spec[:c]
      end

      # True if the class has an underlying equivalent struct member for itself.
      #
      # A class might not have an equivalent struct member even though it
      # wraps a struct. One such example is if it is able to use one of its
      # ancestor's members if it wraps the same struct.
      def self.equivalent_member?(class_spec)
        # there's no equivalent member if there's no wrapped struct
        return false unless class_spec.wrapped.key?(:c)

        # let's see if we can re-use an ancestor's struct
        !equivalent_ancestor?(class_spec)
      end

      # The type of the equivalent struct for a class spec if one exists, nil
      # if not.
      def self.equivalent_type(class_spec)
        class_spec[:c] if class_spec.wrapped.key?(:c)
      end

      # An array with all includes in the given spec. For specs that include
      # others, the array will have all includes of the included items as well.
      # +uniq+ is called on the array before it is returned to remove
      # duplicates.
      def self.includes(spec)
        inc = case spec
              when Scope
                spec.flat_map { |it| includes(it) }
              when ClassSpec
                spec_includes = if spec.wrapped.key?(:c)
                                  spec[:c].includes
                                else
                                  []
                                end
                function_includes = spec.functions.flat_map do |it|
                  includes(it)
                end
                constant_includes = spec.constants.flat_map do |it|
                  includes(it)
                end
                spec_includes + constant_includes + function_includes
              when FunctionSpec
                spec_includes = if spec.wrapped.key?(:c)
                                  spec[:c].includes
                                else
                                  []
                                end
                param_includes = spec.params.flat_map do |it|
                  includes(it)
                end
                spec_includes + param_includes
              when EnumSpec
                # TODO: this should be refactored to use a wrapped :c key
                spec.definition_includes
              when ConstantSpec, ParamSpec, TypeSpec
                # TODO: this should be refactored to use a wrapped :c key
                spec.includes
              else
                []
              end

        inc.uniq
      end
    end
  end
end
