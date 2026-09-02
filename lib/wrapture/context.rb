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

    # Creates a Context with a root ClassSpec constructed from +hash+, and
    # functions derived from the +:functions+ key. If +parent+ is provided, it
    # is the parent of the new Context, but it is not added to the contents of
    # the parent.
    def self.from_class_hash(hash, parent: nil)
      class_spec = ClassSpec.new(hash)
      context = new(class_spec, parent: parent)

      if hash.key?(:functions)
        hash[:functions].each do |it|
          context << FunctionSpec.from_hash(it)
        end
      end

      if hash.key?(:constructors)
        hash[:constructors].each do |it|
          func_spec = FunctionSpec.from_hash(it)
          func_spec.constructor = true
          context << func_spec
        end
      end

      if hash.key?(:destructor)
        func_spec = FunctionSpec.from_hash(hash[:destructor])
        func_spec.destructor = true
        context << func_spec
      end

      context
    end

    # Creates a Context with a root Namespace constructed from +hash+, and
    # contents derived from the +:classes+, +:constants+, +:enums+,
    # and +:functions+ keys. If +parent+ is provided, it is the parent of the
    # new Context, but it is not added to the contents of the parent.
    def self.from_namespace_hash(hash, parent: nil)
      ns = Namespace.from_hash(hash)
      context = new(ns, parent: parent)

      if hash.key?(:classes)
        hash[:classes].each do |it|
          context.contents << from_class_hash(it, parent: context)
        end
      end

      if hash.key?(:constants)
        hash[:constants].each do |it|
          context << ConstantSpec.new(it)
        end
      end

      if hash.key?(:enums)
        hash[:enums].each do |it|
          context << EnumSpec.from_hash(it)
        end
      end

      if hash.key?(:functions)
        hash[:functions].each do |it|
          context << FunctionSpec.from_hash(it)
        end
      end

      context
    end

    # Creates a Context with a root of a Namespace constructed from the hash in
    # the YAML file +filename+. If +parent+ is provided, it is the parent of the
    # new Context, but it is not added to the contents of the parent.
    def self.from_namespace_yaml_file(filename, parent: nil)
      # simplify this to just safe_load_file after Ruby 2.7 is dropped
      ns_hash = if YAML.respond_to?('safe_load_file')
                  YAML.safe_load_file(filename, symbolize_names: true)
                else
                  File.open(filename, 'r:bom|utf-8') do |f|
                    YAML.safe_load(f, filename: filename,
                                      symbolize_names: true)
                  end
                end

      from_namespace_hash(ns_hash, parent: parent)
    end

    # A new Context is created from a +root+ element, and may have a +parent+
    # Context.
    def initialize(root, parent: nil)
      # TODO: there needs to be a parent module/class to describe wrappable
      # specs in some way more concisely than a flat list
      unless root.is_a?(ClassSpec) ||
             root.is_a?(ConstantSpec) ||
             root.is_a?(FunctionSpec) ||
             root.is_a?(EnumSpec) ||
             root.is_a?(Namespace)
        raise InvalidSpec, 'context root must be a wrappable spec'
      end

      if !parent.nil? && !parent.is_a?(Context)
        raise InvalidContext, 'the parent of a Context must be a Context'
      end

      @contents = Set.new
      @parent = parent
      @root = root
    end

    # Adds the given element to the context's contents. A new Context is created
    # with the element as its root and this Context as the parent, and the new
    # Context is added to the contents. The modified Context image is returned.
    def <<(element)
      @contents << Context.new(element, parent: self)

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

    # All contents that are constructor functions.
    def constructors
      @contents.select do |it|
        it.root.is_a?(FunctionSpec) && it.root.constructor?
      end
    end

    # All contents with an EnumSpec root.
    def enums
      @contents.select { |it| it.root.is_a?(EnumSpec) }
    end

    # All contents with a FunctionSpec root.
    def functions
      @contents.select { |it| it.root.is_a?(FunctionSpec) }
    end

    # The functions in this context that are neither constructors nor
    # destructors.
    def methods
      @contents.select do |it|
        it.root.is_a?(FunctionSpec) &&
          !it.root.constructor? &&
          !it.root.destructor?
      end
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

    # Searches through the Context for an element where +block+ returns true and
    # returns the first match, or nil if there are none.
    #
    # Resolution occurs by first checking the root for a match, followed by the
    # context's contents for matches. Note this search does not recursively
    # search through contents. If no match is found in the contents and this
    # context has a parent, then resolution is attempted in the parent. If there
    # is no parent, then the search is ended.
    def resolve(&block)
      return self if block.call(self)

      resolved = contents.find(&block)

      if resolved.nil?
        parent.resolve(&block) if parent?
      else
        resolved
      end
    end

    # Resolves an element with +name_words+ as the name in this context.
    def resolve_name(name_words)
      return nil if name_words.nil?

      resolve do |it|
        it.root.name_words == name_words
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
