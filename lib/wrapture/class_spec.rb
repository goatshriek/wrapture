# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2021 Joel E. Anderson
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
  # A description of a class, including its constants, functions, and other
  # details.
  class ClassSpec
    # Normalizes a hash specification of a class. Normalization will check for
    # things like invalid keys, duplicate entries in include lists, and will set
    # missing keys to their default values (for example, an empty list if no
    # includes are given).
    #
    # If this spec cannot be normalized, for example because it is invalid or
    # it uses an unsupported version type, then an exception is raised.
    def self.normalize_spec_hash(spec)
      raise MissingNamespace unless spec.key?('namespace')
      raise MissingSpecKey, 'name key is required' unless spec.key?('name')

      Comment.validate_doc(spec['doc']) if spec.key?('doc')

      normalized = spec.dup
      normalized.default = []

      normalized['version'] = Wrapture.spec_version(spec)
      normalized['includes'] = Wrapture.normalize_includes(spec['includes'])
      normalized['type'] = ClassSpec.effective_type(normalized)

      if spec.key?('parent')
        includes = Wrapture.normalize_includes(spec['parent']['includes'])
        normalized['parent']['includes'] = includes
      end

      normalized
    end

    # Gives the effective type of the given class spec hash.
    def self.effective_type(spec)
      inferred_pointer_wrapper = spec['constructors'].any? do |func|
        func['wrapped-function']['return']['type'] == EQUIVALENT_POINTER_KEYWORD
      end

      if spec.key?('type')
        valid_types = %w[pointer struct]
        unless valid_types.include?(spec['type'])
          type_message = "#{spec['type']} is not a valid class type"
          raise InvalidSpecKey.new(type_message, valid_keys: valid_types)
        end

        spec['type']
      elsif inferred_pointer_wrapper
        'pointer'
      else
        'struct'
      end
    end

    # The list of constants in this class.
    attr_reader :constants

    # The list of functions in this class.
    attr_reader :functions

    # The scope of this class.
    attr_reader :scope

    # The underlying struct of this class.
    attr_reader :struct

    # Creates a class spec based on the provided hash spec.
    #
    # The scope can be provided if available.
    #
    # The hash must have the following keys:
    # name:: the name of the class
    # namespace:: the namespace to put the class into
    # equivalent-struct:: a hash describing the struct this class wraps
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this class
    # constructors:: a list of function specs that can create this class
    # destructor:: a function spec for the destructor of the class
    # functions:: a list of function specs
    # constants:: a list of constant specs
    def initialize(spec, scope: Scope.new)
      @spec = Marshal.load(Marshal.dump(spec))
      TemplateSpec.replace_all_uses(@spec, *scope.templates)

      @spec = ClassSpec.normalize_spec_hash(@spec)

      @struct = if @spec.key?(EQUIVALENT_STRUCT_KEYWORD)
                  StructSpec.new(@spec[EQUIVALENT_STRUCT_KEYWORD])
                end

      @functions = @spec['constructors'].map do |constructor_spec|
        full_spec = constructor_spec.dup
        full_spec['name'] = @spec['name']
        full_spec['params'] = constructor_spec['wrapped-function']['params']

        FunctionSpec.new(full_spec, self, constructor: true)
      end

      if @spec.key?('destructor')
        destructor_spec = @spec['destructor'].dup
        destructor_spec['name'] = "~#{@spec['name']}"

        @functions << FunctionSpec.new(destructor_spec, self, destructor: true)
      end

      @spec['functions'].each do |function_spec|
        @functions << FunctionSpec.new(function_spec, self)
      end

      @constants = @spec['constants'].map do |constant_spec|
        ConstantSpec.new(constant_spec)
      end

      @doc = @spec.key?('doc') ? Comment.new(@spec['doc']) : nil

      scope << self
      @scope = scope
    end

    # Returns a cast of an instance of this class with the provided name to the
    # specified type. Optionally the from parameter may hold the type of the
    # instance, either a reference or a pointer.
    def cast(var_name, to, from = name)
      member_access = from.pointer? ? '->' : '.'

      struct = "struct #{@struct.name}"

      if [EQUIVALENT_STRUCT_KEYWORD, struct].include?(to)
        "#{'*' if pointer_wrapper?}#{var_name}#{member_access}equivalent"
      elsif [EQUIVALENT_POINTER_KEYWORD, "#{struct} *"].include?(to)
        "#{'&' unless pointer_wrapper?}#{var_name}#{member_access}equivalent"
      end
    end

    # True if the class has a parent.
    def child?
      @spec.key?('parent')
    end

    # A list of includes needed for the declaration of the class.
    def declaration_includes
      includes = @spec['includes'].dup

      includes.concat(@struct.includes) if @struct

      @functions.each do |func|
        includes.concat(func.declaration_includes)
      end

      @constants.each do |const|
        includes.concat(const.declaration_includes)
      end

      includes.concat(@spec['parent']['includes']) if child?

      includes.uniq
    end

    # A list of includes needed for the definition of the class.
    def definition_includes
      includes = ["#{@spec['name']}.hpp"]

      includes.concat(@spec['includes'])

      @functions.each do |func|
        includes.concat(func.definition_includes)
      end

      @constants.each do |const|
        includes.concat(const.definition_includes)
      end

      includes.concat(factory_definition_includes)

      includes.uniq
    end

    # Calls the given block for each line of the class documentation.
    def documentation(&block)
      @doc&.format_as_doxygen(max_line_length: 78) { |line| block.call(line) }
    end

    # True if this class has an underlying equivalent struct member for itself.
    #
    # A class might not have an equivalent struct member even though it is
    # based on a struct. One such example is if it is able to use its parent
    # class member since the parent wraps the same struct.
    def equivalent_member?
      return false unless @struct
      return true unless child?

      parent_spec = @scope.type(TypeSpec.new(parent_name))

      parent_spec.nil? ||
        parent_spec.struct_name != struct_name ||
        parent_spec.pointer_wrapper? != pointer_wrapper?
    end

    # True if this class can be used as a factory for children classes that it
    # overloads.
    def factory?
      @scope.overloads?(self)
    end

    # The name of the class.
    def name
      @spec['name']
    end

    # The namespace of the class.
    def namespace
      @spec['namespace']
    end

    # True if this class overloads the given one. A class is considered an
    # overload of its parent if it has the same equivalent struct name and
    # the equivalent struct has a set of rules. The overloaded parent class
    # cannot have any rules in its equivalent struct or it will not be
    # considered an overload.
    def overloads?(parent_spec)
      return false unless parent_spec.struct&.rules&.empty? && @struct

      parent_spec.struct.name == struct_name &&
        parent_spec.name == parent_name &&
        !@struct.rules.empty?
    end

    # The name of the parent of this class, or nil if there is no parent.
    def parent_name
      @spec['parent']['name'] if child?
    end

    # True if the parent of this class provides an initializer taking a pointer
    # to the same equivalent struct type.
    def parent_provides_initializer?
      return false if !pointer_wrapper? || !child?

      parent_spec = @scope.type(TypeSpec.new(parent_name))

      !parent_spec.nil? &&
        parent_spec.pointer_wrapper? &&
        parent_spec.struct_name == @struct.name
    end

    # Determines if this class is a wrapper for a struct pointer or not.
    def pointer_wrapper?
      @spec['type'] == 'pointer'
    end

    # The name of the equivalent struct of this class.
    def struct_name
      @struct.name
    end

    # Gives a code snippet that accesses the equivalent struct from within the
    # class using the 'this' keyword.
    def this_struct
      if pointer_wrapper?
        '*(this->equivalent)'
      else
        'this->equivalent'
      end
    end

    # Gives a code snippet that accesses the equivalent struct pointer from
    # within the class using the 'this' keyword.
    def this_struct_pointer
      "#{'&' unless pointer_wrapper?}this->equivalent"
    end

    # Returns the ClassSpec for the given type in this class's scope.
    def type(type)
      @scope.type(type)
    end

    # Returns true if the given type exists in this class's scope.
    def type?(type)
      @scope.type?(type)
    end

    private

    # A list of the includes needed for the factory function definition.
    def factory_definition_includes
      @scope.overloads(self).map { |overload| "#{overload.name}.hpp" }
    end
  end
end
