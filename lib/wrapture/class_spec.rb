# frozen_string_literal: true

require 'wrapture/constant_spec'
require 'wrapture/function_spec'
require 'wrapture/normalize'

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

      normalized = spec.dup
      normalized.default = []

      normalized['version'] = Wrapture.spec_version(spec)
      normalized['includes'] = Wrapture.normalize_includes(spec['includes'])

      normalized
    end

    # Returns a string of the variable with it's type, properly formatted.
    def self.typed_variable(type, name)
      if type.end_with? '*'
        "#{type}#{name}"
      else
        "#{type} #{name}"
      end
    end

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
    # constructors:: a list of function specs that can create this class
    # destructor:: a function spec for the destructor of the class
    # functions:: a list of function specs
    # constants:: a list of constant specs
    def initialize(spec, scope: Scope.new)
      @spec = ClassSpec.normalize_spec_hash(spec)

      @struct = StructSpec.new @spec[EQUIVALENT_STRUCT_KEYWORD]

      @functions = []
      @spec['constructors'].each do |constructor_spec|
        function_spec = constructor_spec.dup
        function_spec['name'] = @spec['name']
        function_spec['params'] = constructor_spec['wrapped-function']['params']

        @functions << FunctionSpec.new(function_spec, self, constructor: true)
      end

      @spec['functions'].each do |function_spec|
        @functions << FunctionSpec.new(function_spec, self)
      end

      @constants = []
      @spec['constants'].each do |constant_spec|
        @constants << ConstantSpec.new(constant_spec)
      end

      scope << self
      @scope = scope
    end

    # Returns a cast of an instance of this class to the provided type, if
    # possible.
    def cast_to(name, type)
      struct = "struct #{@struct.name}"

      if ['equivalent-struct', struct].include?(type)
        equivalent_struct(name)
      elsif ['equivalent-struct-pointer', "#{struct} *"].include?(type)
        equivalent_struct_pointer(name)
      end
    end

    # The equivalent struct of this class from an instance of it.
    def equivalent_struct(instance_name)
      if pointer_wrapper?
        "*#{instance_name}.equivalent"
      else
        "#{instance_name}.equivalent"
      end
    end

    # A pointer to the equivalent struct of this class from an instance of it.
    def equivalent_struct_pointer(instance_name)
      if pointer_wrapper?
        "#{instance_name}.equivalent"
      else
        "&#{instance_name}.equivalent"
      end
    end

    # Generates the wrapper class declaration and definition files.
    def generate_wrappers
      files = []
      files << generate_declaration_file
      files << generate_definition_file
    end

    # The name of the class
    def name
      @spec['name']
    end

    # Returns a string for the provided parameter that can be used within the
    # class's code.
    def resolve_param(param)
      case param
      when 'equivalent-struct'
        this_struct
      when 'equivalent-struct-pointer'
        this_struct_pointer
      else
        param
      end
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
      if pointer_wrapper?
        'this->equivalent'
      else
        '&this->equivalent'
      end
    end

    # Returns the ClassSpec for the given type in this class's scope.
    def type(type)
      @scope.type(type)
    end

    # Returns true if the given type exists in this class's scope.
    def type?(type)
      @scope.type?(type)
    end

    # A string calling the wrapped function spec, with resolved parameters.
    def function_call(spec)
      resolved_params = []

      spec['params'].each do |param|
        resolved_params << resolve_param(param['name'])
      end

      "#{spec['name']}( #{resolved_params.join ', '} )"
    end

    private

    # The header guard for the class.
    def header_guard
      "__#{@spec['name'].upcase}_HPP"
    end

    # A list of includes needed for the declaration of the class.
    def declaration_includes
      includes = @spec['includes'].dup

      includes.concat @struct.includes

      @functions.each do |func|
        includes.concat func.declaration_includes
      end

      @constants.each do |const|
        includes.concat const.declaration_includes
      end

      includes.uniq
    end

    # A list of includes needed for the definition of the class.
    def definition_includes
      includes = ["#{@spec['name']}.hpp"]

      includes.concat @spec['includes']

      @functions.each do |func|
        includes.concat func.definition_includes
      end

      @constants.each do |const|
        includes.concat const.definition_includes
      end

      includes.uniq
    end

    # Determines if this class is a wrapper for a struct pointer or not.
    def pointer_wrapper?
      @spec['constructors'].each do |constructor_spec|
        return_type = constructor_spec['wrapped-function']['return']['type']

        return true if return_type == 'equivalent-struct-pointer'
      end

      false
    end

    # Gives the name of the equivalent struct.
    def equivalent_name
      if pointer_wrapper?
        '*equivalent'
      else
        'equivalent'
      end
    end

    # Gives a code snippet that accesses a member of the equivalent struct for
    # this class within the class using the 'this' keyword.
    def this_member(member)
      if pointer_wrapper?
        "this->equivalent->#{member}"
      else
        "this->equivalent.#{member}"
      end
    end

    # The signature of the destructor.
    def destructor_signature
      "~#{@spec['name']}( void )"
    end

    # The definition of the member constructor for a class. This is only valid
    # when the class is not a pointer wrapper.
    def member_constructor_signature
      "#{@spec['name']}( #{@struct.member_list} )"
    end

    # The signature of the constructor given an equivalent struct type.
    def struct_constructor_signature
      "#{@spec['name']}( #{@struct.declaration 'equivalent'} )"
    end

    # The signature of the constructor given an equivalent strucct pointer.
    def pointer_constructor_signature
      "#{@spec['name']}( #{@struct.pointer_declaration 'equivalent'} )"
    end

    # Generates the declaration of the class.
    def generate_declaration_file
      filename = "#{@spec['name']}.hpp"

      File.open(filename, 'w') do |file|
        declaration_contents do |line|
          file.puts line
        end
      end

      filename
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
      yield "  class #{@spec['name']} {"
      yield '  public:'

      yield unless @constants.empty?
      @constants.each do |const|
        yield "    #{const.declaration};"
      end

      yield
      yield "    #{@struct.declaration equivalent_name};"
      yield

      yield "    #{member_constructor_signature};" if @struct.members?

      unless pointer_wrapper?
        yield "    #{struct_constructor_signature};"
        yield "    #{pointer_constructor_signature};"
      end

      yield "    #{destructor_signature};" if @spec.key? 'destructor'

      @functions.each do |func|
        yield "    #{func.declaration};"
      end

      yield '  };' # end of class
      yield
      yield '}' # end of namespace
      yield
      yield '#endif' # end of header guard
    end

    # Generates the definition of the class.
    def generate_definition_file
      filename = "#{@spec['name']}.cpp"

      File.open(filename, 'w') do |file|
        definition_contents do |line|
          file.puts line
        end
      end

      filename
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
        yield "  #{const.definition @spec['name']};"
      end

      if @struct.members?
        yield
        yield "  #{@spec['name']}::#{member_constructor_signature} {"

        @struct.members.each do |member|
          member_decl = this_member(member['name'])
          yield "    #{member_decl} = #{member['name']};"
        end

        yield '  }'
      end

      unless pointer_wrapper?
        yield
        yield "  #{@spec['name']}::#{struct_constructor_signature} {"

        @struct.members.each do |member|
          member_decl = this_member(member['name'])
          yield "    #{member_decl} = equivalent.#{member['name']};"
        end

        yield '  }'

        yield
        yield "  #{@spec['name']}::#{pointer_constructor_signature} {"

        @struct.members.each do |member|
          member_decl = this_member(member['name'])
          yield "    #{member_decl} = equivalent->#{member['name']};"
        end

        yield '  }'
      end

      if @spec.key? 'destructor'
        yield
        yield "  #{@spec['name']}::#{destructor_signature} {"
        func_spec = @spec['destructor']['wrapped-function']
        yield "    #{function_call func_spec};"
        yield '  }'
      end

      @functions.each do |func|
        yield

        func.definition(@spec['name']) do |def_line|
          yield "  #{def_line}"
        end
      end

      yield
      yield '}' # end of namespace
    end
  end
end
