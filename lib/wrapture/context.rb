# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2026 Joel E. Anderson
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
  # A context represents a specific collection of specs and namespaces. This
  # provides the information needed to resolve relative references within specs
  # during wrapper generation. For example, a function being used as a method
  # in a class will resolve the type of the self/this instance using the
  # context it is invoked within.
  #
  # A Context has three attributes: a Named root element, a set of Context
  # instances called contents, and a Context instance named parent.
  class Context
    include Named

    # A Set of Context instance which this context directly contains.
    attr_reader :contents

    # A Context that contains this one. If this is nil, then this Context is at
    # the top of the tree.
    attr_reader :parent

    # The root of this context.
    attr_reader :root

    # Creates a Context with a root of a Namespace constructed from +hash+, and
    # contents derived from the +:classes+, +:constants+, +:enums+,
    # and +:functions+ keys.
    def self.from_namespace_hash(spec)
      root = Namespace.from_hash(spec)
      context = new(root)

      if spec.key?(:classes)
        spec[:classes].each do |it|
          context << ClassSpec.new(it)
        end
      end

      if spec.key?(:constants)
        spec[:constants].each do |it|
          context << ConstantSpec.new(it)
        end
      end

      if spec.key?(:enums)
        spec[:enums].each do |it|
          context << EnumSpec.from_hash(it)
        end
      end

      if spec.key?(:functions)
        spec[:functions].each do |it|
          context << FunctionSpec.from_hash(it)
        end
      end

      context
    end

    # A new Context is created from a source element, and may have a +parent+
    # Context.
    def initialize(root, parent: nil)
      @contents = Set.new
      @parent = parent
      @root = root
    end

    # Adds the given element to the context's contents. If the element is
    # a Context instance then it is added directly, otherwise a new Context
    # is created with the element as its root and this Context as the parent,
    # and the new Context is added to the contents. The modified Context image
    # is returned in either case.
    def <<(element)
      @contents << if element.is_a?(Context)
                     element
                   else
                     Context.new(element, parent: self)
                   end

      self
    end

    # All contents with a ClassSpec root.
    def classes
      @contents.select { |it| it.root.is_a?(ClassSpec) }
    end

    # All contents with a ConstantSpec root.
    def constants
      @contents.select { |it| it.root.is_a?(ConstantSpec) }
    end

    # All contents with an EnumSpec root.
    def enums
      @contents.select { |it| it.root.is_a?(EnumSpec) }
    end

    # All contents with a FunctionSpec root.
    def functions
      @contents.select { |it| it.root.is_a?(FunctionSpec) }
    end

    # The name words for this context.
    def name_words
      @root.name_words
    end

    # All contents with a Namespace root.
    def namespaces
      @contents.select { |it| it.root.is_a?(Namespace) }
    end

    # True if this context has a parent.
    def parent?
      !@parent.nil?
    end

    # Searches through the Context and its contents to see if any elements
    # have the name +name_words+. Returns the match if one is found, or nil if
    # no matches are found. The match search is case sensitive.
    #
    # Resolution occurs by searching the context's contents for matches. Note
    # this search does not recursively search through contents. If no match is
    # found in the contents and this context has a parent, then resolution is
    # attempted in the parent. If there is no parent, then the search is ended.
    def resolve_name(name_words)
      return root if name_words == root.name_words

      resolved = contents.find do |it|
        it.name_words == name_words
      end

      if resolved.nil?
        parent.resolve_name(name_words) if parent?
      else
        resolved
      end
    end

    # The topmost parent of this context.
    def top
      if parent?
        parent.top
      else
        self
      end
    end
  end
end
