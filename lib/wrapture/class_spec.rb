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
      raise NoNamespace unless spec.key?('namespace')
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

    # Generates the wrapper class declaration and definition files.
    def generate_wrappers
      [generate_declaration_file, generate_definition_file]
    end

    # The name of the class
    def name
      @spec['name']
    end

    # True if this class overloads the given one. A class is considered an
    # overload if its parent is the given class, it has the same equivalent
    # struct name, and the equivalent struct has a set of rules. The overloaded
    # class cannot have any rules in its equivalent struct, or it will not be
    # overloaded.
    def overloads?(parent_spec)
      return false unless parent_spec.struct&.rules&.empty?

      parent_spec.struct.name == struct_name &&
        parent_spec.name == parent_name &&
        !@struct.rules.empty?
    end

    # The name of the parent of this class, or nil if there is no parent.
    def parent_name
      @spec['parent']['name'] if child?
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

    # Gives the content of the class declaration to a block, line by line.
    def declaration_contents
      yield "#ifndef #{header_guard}"
      yield "#define #{header_guard}"

      yield unless declaration_includes.empty?
      declaration_includes.each do |include_file|
        yield "#include <#{include_file}>"
      end

      yield
      yield "namespace #{@spec['namespace']} {"
      yield

      documentation { |line| yield "  #{line}" }
      parent = if child?
                 ": public #{parent_name} "
               else
                 ''
               end
      yield "  class #{@spec['name']} #{parent}{"

      yield '  public:'

      yield unless @constants.empty?
      @constants.each do |const|
        const.declaration { |line| yield "    #{line}" }
      end

      yield
      equivalent_member_declaration { |line| yield "    #{line}" }
      yield

      member_constructor_declaration { |line| yield "    #{line}" }

      pointer_constructor_declaration { |line| yield "    #{line}" }

      unless !@struct || pointer_wrapper?
        yield "    #{struct_constructor_signature};"
      end

      overload_declaration { |line| yield "    #{line}" }

      @functions.each do |func|
        func.declaration { |line| yield "    #{line}" }
      end

      yield '  };' # end of class
      yield
      yield '}' # end of namespace
      yield
      yield '#endif' # end of header guard
    end

    # Gives the content of the class definition to a block, line by line.
    def definition_contents
      definition_includes.each do |include_file|
        yield "#include <#{include_file}>"
      end

      yield
      yield "namespace #{@spec['namespace']} {"

      yield unless @constants.empty?
      @constants.each do |const|
        yield "  #{const.definition(@spec['name'])};"
      end

      member_constructor_definition { |line| yield "  #{line}" }

      pointer_constructor_definition { |line| yield "  #{line}" }

      unless pointer_wrapper? || !@struct
        yield
        yield "  #{@spec['name']}::#{struct_constructor_signature} {"

        @struct.members.each do |member|
          member_decl = this_member(member['name'])
          yield "    #{member_decl} = equivalent.#{member['name']};"
        end

        yield '  }'
      end

      overload_definition { |line| yield "  #{line}" }

      @functions.each do |func|
        yield

        func.definition do |def_line|
          yield "  #{def_line}"
        end
      end

      yield
      yield '}' # end of namespace
    end

    private

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

      includes.concat(overload_definition_includes)

      includes.uniq
    end

    # Calls the given block for each line of the class documentation.
    def documentation(&block)
      @doc&.format_as_doxygen(max_line_length: 78) { |line| block.call(line) }
    end

    # Yields the declaration of the equivalent member if this class has one.
    #
    # A class might not have an equivalent member if it is able to use the
    # parent class's, for example if the child class wraps the same struct.
    def equivalent_member_declaration
      return unless @struct

      if child?
        parent_spec = @scope.type(TypeSpec.new(parent_name))
        member_reusable = !parent_spec.nil? &&
                          parent_spec.struct_name == @struct.name &&
                          parent_spec.pointer_wrapper? == pointer_wrapper?
        return if member_reusable
      end

      yield "#{@struct.declaration(equivalent_name)};"
    end

    # Gives the name of the equivalent struct.
    def equivalent_name
      "#{'*' if pointer_wrapper?}equivalent"
    end

    # Generates the declaration of the class.
    def generate_declaration_file
      filename = "#{@spec['name']}.hpp"

      File.open(filename, 'w') do |file|
        declaration_contents do |line|
          file.puts(line)
        end
      end

      filename
    end

    # Generates the definition of the class.
    def generate_definition_file
      filename = "#{@spec['name']}.cpp"

      File.open(filename, 'w') do |file|
        definition_contents do |line|
          file.puts(line)
        end
      end

      filename
    end

    # The header guard for the class.
    def header_guard
      "__#{@spec['name'].upcase}_HPP"
    end

    # Yields the declaration of the member constructor for a class. This will be
    # empty if the wrapped struct is a pointer wrapper.
    def member_constructor_declaration
      return unless @struct&.members?

      yield "#{@spec['name']}( #{@struct.member_list_with_defaults} );"
    end

    # Yields the definition of the member constructor for a class. This will be
    # empty if the wrapped struct is a pointer wrapper.
    def member_constructor_definition
      return unless @struct&.members?

      yield "#{@spec['name']}::#{@spec['name']}( #{@struct.member_list} ) {"

      @struct.members.each do |member|
        member_decl = this_member(member['name'])
        yield "  #{member_decl} = #{member['name']};"
      end

      yield '}'
    end

    # Yields the declaration of the overload function for this class. If there
    # is no overload function for this class, then nothing is yielded.
    def overload_declaration
      return unless @scope.overloads?(self)

      yield "static #{name} *new#{name}( struct #{@struct.name} *equivalent );"
    end

    # Yields each line of the definition of the overload function, with a
    # leading empty yield. If there is no overload function for this class,
    # then nothing is yielded.
    def overload_definition
      return unless @scope.overloads?(self)

      yield

      parameter = "struct #{@struct.name} *equivalent"
      yield "#{name} *#{name}::new#{name}( #{parameter} ) {"

      line_prefix = '  '
      @scope.overloads(self).each do |overload|
        check = overload.struct.rules_check('equivalent')
        yield "#{line_prefix}if( #{check} ) {"
        yield "    return new #{overload.name}( equivalent );"
        line_prefix = '  } else '
      end

      yield "#{line_prefix}{"
      yield "    return new #{name}( equivalent );"
      yield '  }'
      yield '}'
    end

    # A list of the includes needed for the overload definitions.
    def overload_definition_includes
      @scope.overloads(self).map { |overload| "#{overload.name}.hpp" }
    end

    # The initializer for the pointer constructor, if one is available, or an
    # empty string if not.
    def parent_provides_initializer?
      return false if !pointer_wrapper? || !child?

      parent_spec = @scope.type(TypeSpec.new(parent_name))

      !parent_spec.nil? &&
        parent_spec.pointer_wrapper? &&
        parent_spec.struct_name == @struct.name
    end

    # Yields the declaration of the pointer constructor for a class.
    #
    # If this class does not have an equivalent struct, or if there is already
    # a constructor defined with this signature, then this function will return
    # with no output.
    def pointer_constructor_declaration
      return unless @struct

      signature_prefix = "#{@spec['name']}( #{@struct.pointer_declaration('')}"
      return if @functions.any? do |func|
        func.constructor? && func.signature.start_with?(signature_prefix)
      end

      yield "#{pointer_constructor_signature};"
    end

    # Yields the definition of the pointer constructor for a class.
    #
    # If this class has no equivalent struct, or if there is already a
    # constructor provided with this signature, then this function will return
    # with no output.
    #
    # If this is a pointer wrapper class, then the constructor will simply set
    # the underlying pointer to the provided one, and return the new object.
    #
    # If this is a struct wrapper class, then a constructor will be created that
    # sets each member of the wrapped struct to the provided value.
    def pointer_constructor_definition
      return unless @struct

      signature_prefix = "#{@spec['name']}( #{@struct.pointer_declaration('')}"
      return if @functions.any? do |func|
        func.constructor? && func.signature.start_with?(signature_prefix)
      end

      initializer = pointer_constructor_initializer
      yield "#{@spec['name']}::#{pointer_constructor_signature} #{initializer}{"

      if pointer_wrapper?
        yield '  this->equivalent = equivalent;'
      else
        @struct.members.each do |member|
          member_decl = this_member(member['name'])
          yield "  #{member_decl} = equivalent->#{member['name']};"
        end
      end

      yield '}'
    end

    # The initializer for the pointer constructor, if one is available, or an
    # empty string if not.
    def pointer_constructor_initializer
      if parent_provides_initializer?
        ": #{parent_name}( equivalent ) "
      else
        ''
      end
    end

    # The signature of the constructor given an equivalent strucct pointer.
    def pointer_constructor_signature
      "#{@spec['name']}( #{@struct.pointer_declaration 'equivalent'} )"
    end

    # The signature of the constructor given an equivalent struct type.
    def struct_constructor_signature
      "#{@spec['name']}( #{@struct.declaration 'equivalent'} )"
    end

    # Gives a code snippet that accesses a member of the equivalent struct for
    # this class within the class using the 'this' keyword.
    def this_member(member)
      "this->equivalent#{pointer_wrapper? ? '->' : '.'}#{member}"
    end
  end
end
