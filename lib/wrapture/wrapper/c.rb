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
  module Wrapper
    # Utilities for wrappers that use C as either a from or to language.
    module C
      # Makes a decorated version of the given name so that it is unique among
      # other wrapper names based on the C language. This is done by prepending
      # "c" to the name, for example "MyLib" will become "CMyLib".
      def self.decorate_name_words(name_words)
        ['c'] + name_words
      end

      # True if one of the ancestors of the ClassSpec at the root of +context+
      # has an equivalent struct that it can use.
      def self.equivalent_ancestor?(context)
        # TODO: remove
        unless context.is_a?(Context)
          raise InvalidContext, 'equivalent member without Context'
        end

        return false unless context.is_a?(Context)

        class_spec = context.root
        return false unless class_spec.child?

        parent_context = context.resolve_name(context.root.parent)
        until parent_context.nil?
          parent_source = parent_context.root.source
          if parent_source.key?(:c) && parent_source[:c] == class_spec[:c]
            return true
          else
            next_parent_name = parent_context.root.parent
            parent_context = parent_context.resolve_name(next_parent_name)
          end
        end
      end

      # True if the class at the root of +context+ has an underlying equivalent
      # struct member for itself.
      #
      # A class might not have an equivalent struct member even though it
      # wraps a struct. One such example is if it is able to use one of its
      # ancestor's members if it wraps the same struct.
      def self.equivalent_member?(context)
        # TODO: remove
        unless context.is_a?(Context)
          raise InvalidContext, 'equivalent member without Context'
        end

        # there's no equivalent member if there's no wrapped struct
        unless context.is_a?(Context) && context.root.source.key?(:c)
          return false
        end

        # let's see if we can re-use an ancestor's struct
        !equivalent_ancestor?(context)
      end

      # The equivalent struct pointer type for a class spec if an underlying
      # struct exists, nil if not. If the class wraps a struct directly, this
      # type will be a pointer to the struct type, not the struct type itself.
      def self.equivalent_pointer(class_spec)
        if class_spec.source.key?(:c)
          if class_spec[:c].instance_of?(CSource::CStruct)
            CSource::CPointer.new(class_spec[:c])
          else
            class_spec[:c]
          end
        end
      end

      # The equivalent struct type for a class spec if one exists, nil if not.
      # If the class wraps a pointer to a struct, this type will be the struct
      # type, not the pointer type.
      def self.equivalent_struct(class_spec)
        if class_spec.source.key?(:c)
          if class_spec[:c].instance_of?(CSource::CPointer)
            class_spec[:c].c_type
          else
            class_spec[:c]
          end
        end
      end

      # The type of the equivalent struct for a class spec if one exists, nil
      # if not.
      def self.equivalent_type(class_spec)
        class_spec[:c] if class_spec.source.key?(:c)
      end

      # True if the ClassSpec at the root of +context+ is a factory. A factory
      # class can generate instances of different classes from the same struct,
      # based on rules specified for each class.
      #
      # In order for a class to be a factory, it must have at least one child
      # class that wraps the same struct, and has rules associated with it. The
      # factory class itself may not have any rules associated with its struct.
      #
      # TODO: can the child and no rules in the parent rules be relaxed?
      def self.factory?(context)
        class_spec = context.root
        class_struct = equivalent_struct(class_spec)
        return false if class_struct.nil?

        unless class_struct.rules.empty? && equivalent_member?(context)
          return false
        end

        overloaded_class = context.resolve do |it|
          next unless it.root.is_a?(ClassSpec)
          next unless it.root.child?

          other_struct = equivalent_struct(it.root)
          next if other_struct.nil? || other_struct.rules.empty?

          # TODO: this needs to be update to only use name words
          parent_name = Named.upper_camel_case_name(it.root.parent)

          class_struct.name == other_struct.name &&
            class_spec.upper_camel_case_name == parent_name
        end

        !overloaded_class.nil?
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
                spec_includes = if spec.source.key?(:c)
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
                spec_includes = if spec.source.key?(:c)
                                  spec[:c].includes
                                else
                                  []
                                end
                param_includes = spec.params.flat_map do |it|
                  includes(it)
                end
                spec_includes + param_includes
              when EnumSpec
                spec_includes = []

                spec_includes += spec[:c][:includes] if spec.source.key?(:c)

                spec.elements.each do |it|
                  it_inc = it.dig(:source, :c, :includes)
                  spec_includes += it_inc unless it_inc.nil?
                end

                spec_includes
              when ConstantSpec, ParamSpec, TypeSpec
                # TODO: this should be refactored to use a wrapped :c key
                spec.includes
              else
                []
              end

        inc.uniq
      end

      # True if the ClassSpec +overload+ is an overload of the ClassSpec
      # +factory+. That is, if the wrapped struct of the overload class is the
      # same as that of the factory class, with additional rules.
      def self.overload?(factory, overload)
        return false unless overload.child?

        factory_struct = equivalent_struct(factory)
        overload_struct = equivalent_struct(overload)
        # TODO: this should compare name words, not specific name forms
        factory_name = factory.upper_camel_case_name
        parent_name = Named.upper_camel_case_name(overload.parent)

        !factory_struct.nil? &&
          !overload_struct.nil? &&
          factory_struct.rules.empty? &&
          factory_struct.name == overload_struct.name &&
          factory_name == parent_name &&
          !overload_struct.rules.empty?
      end

      # An array of contexts with root classes that overload the class at the
      # root of +context+.
      #
      # The contents of the parent of +context+ are searched recursively for any
      # overloads. If +search_from+ is provided, the search is started there
      # instead of at the parent of +context+.
      def self.overloads(context, search: nil)
        [] unless factory?(context)

        search = context.parent if search.nil?
        search = context if search.nil?

        search.contents.flat_map do |it|
          if overload?(context.root, it.root)
            overloads(context, search: it) + [it]
          else
            overloads(context, search: it)
          end
        end
      end

      # True if the given class wraps a struct (not a pointer) with members
      # defined in it. This is useful for determing if a constructor or
      # accessors can be generated based on the fields.
      def self.wrapped_members?(class_spec)
        class_spec.source.key?(:c) &&
          class_spec[:c].is_a?(CSource::CStruct) &&
          !class_spec[:c].members.empty?
      end
    end
  end
end
