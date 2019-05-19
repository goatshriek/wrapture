# frozen_string_literal: true

require 'wrapture/constant_spec'
require 'wrapture/function_spec'

module Wrapture
  ##
  # A description of a class, including its constants, functions, and other
  # details.
  class ClassSpec
    def self.typed_variable(type, name)
      if type.end_with? '*'
        "#{type}#{name}"
      else
        "#{type} #{name}"
      end
    end

    def initialize(spec)
      @spec = ClassSpec.normalize_spec_hash(spec)

      @functions = []
      @spec['functions'].each do |function_spec|
        @functions << FunctionSpec.new(function_spec, self)
      end

      @constants = []
      @spec['constants'].each do |constant_spec|
        @constants << ConstantSpec.new(constant_spec)
      end
    end

    def generate_wrappers
      files = []
      files << generate_declaration_file
      files << generate_definition_file
    end

    def resolve_param(param)
      case param
      when 'equivalent-struct'
        equivalent_struct
      when 'equivalent-struct-pointer'
        equivalent_struct_pointer
      else
        param
      end
    end

    def function_call(spec)
      resolved_params = []

      spec['params'].each do |param|
        resolved_params << resolve_param(param['name'])
      end

      "#{spec['name']}( #{resolved_params.join ', '} )"
    end

    def self.normalize_spec_hash(spec)
      normalized_spec = spec.dup
      normalized_spec.default = []

      normalized_spec['equivalent-struct']['members'] ||= []

      normalized_spec
    end

    private

    def header_guard
      "__#{@spec['name'].upcase}_HPP"
    end

    def declaration_includes
      includes = @spec['equivalent-struct']['includes'].dup

      @functions.each do |func|
        includes.concat func.declaration_includes
      end

      @constants.each do |const|
        includes.concat const.declaration_includes
      end

      includes.uniq
    end

    def definition_includes
      includes = ["#{@spec['name']}.hpp"]

      @functions.each do |func|
        includes.concat func.definition_includes
      end

      @constants.each do |const|
        includes.concat const.definition_includes
      end

      includes.uniq
    end

    def pointer_wrapper?
      @spec['constructors'].each do |constructor_spec|
        return_type = constructor_spec['wrapped-function']['return']['type']

        return true if return_type == 'equivalent-struct-pointer'
      end

      false
    end

    def equivalent_member(member)
      if pointer_wrapper?
        "this->equivalent->#{member}"
      else
        "this->equivalent.#{member}"
      end
    end

    def equivalent_name
      if pointer_wrapper?
        '*equivalent'
      else
        'equivalent'
      end
    end

    def equivalent_struct
      if pointer_wrapper?
        '*(this->equivalent)'
      else
        'this->equivalent'
      end
    end

    def equivalent_struct_pointer
      if pointer_wrapper?
        'this->equivalent'
      else
        '&this->equivalent'
      end
    end

    def wrapped_constructor_signature(index)
      function_spec = @spec['constructors'][index]['wrapped-function']

      "#{@spec['name']}( #{FunctionSpec.param_list function_spec} )"
    end

    def destructor_signature
      "~#{@spec['name']}( void )"
    end

    def wrapped_constructor_definition(index)
      constructor_spec = @spec['constructors'][index]
      wrapped_function = constructor_spec['wrapped-function']

      yield "#{@spec['name']}::#{wrapped_constructor_signature(index)}{"

      result = resolve_param wrapped_function['return']['type']

      yield "  #{result} = #{function_call wrapped_function};"

      yield '}'
    end

    def member_constructor_signature
      params = []

      @spec['equivalent-struct']['members'].each do |member|
        params << ClassSpec.typed_variable(member['type'], member['name'])
      end

      "#{@spec['name']}( #{params.join ', '} )"
    end

    def struct_constructor_signature
      struct_name = @spec['equivalent-struct']['name']
      "#{@spec['name']}( struct #{struct_name} equivalent )"
    end

    def pointer_constructor_signature
      struct_name = @spec['equivalent-struct']['name']
      "#{@spec['name']}( struct #{struct_name} *equivalent )"
    end

    def generate_declaration_file
      filename = "#{@spec['name']}.hpp"

      File.open(filename, 'w') do |file|
        declaration_contents do |line|
          file.puts line
        end
      end

      filename
    end

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
        yield "  #{const.declaration};"
      end

      yield
      struct_name = @spec['equivalent-struct']['name']
      yield "    struct #{struct_name} #{equivalent_name};"
      yield

      unless @spec['equivalent-struct']['members'].empty?
        yield "    #{member_constructor_signature};"
      end

      unless pointer_wrapper?
        yield "    #{struct_constructor_signature};"
        yield "    #{pointer_constructor_signature};"
      end

      @spec['constructors'].each_index do |constructor|
        yield "    #{wrapped_constructor_signature constructor};"
      end

      yield "    #{destructor_signature};" if @spec.key? 'destructor'

      @functions.each do |func|
        yield "    #{func.signature};"
      end

      yield '  };' # end of class
      yield
      yield '}' # end of namespace
      yield
      yield '#endif' # end of header guard
    end

    def generate_definition_file
      filename = "#{@spec['name']}.cpp"

      File.open(filename, 'w') do |file|
        definition_contents do |line|
          file.puts line
        end
      end

      filename
    end

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

      unless @spec['equivalent-struct']['members'].empty?
        yield
        yield "  #{@spec['name']}::#{member_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          member_decl = equivalent_member member['name']
          yield "    #{member_decl} = #{member['name']};"
        end

        yield '  }'
      end

      unless pointer_wrapper?
        yield
        yield "  #{@spec['name']}::#{struct_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          member_decl = equivalent_member member['name']
          yield "    #{member_decl} = equivalent.#{member['name']};"
        end

        yield '  }'

        yield
        yield "  #{@spec['name']}::#{pointer_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          member_decl = equivalent_member member['name']
          yield "    #{member_decl} = equivalent->#{member['name']};"
        end

        yield '  }'
      end

      @spec['constructors'].each_index do |constructor|
        yield
        wrapped_constructor_definition(constructor) do |line|
          yield "  #{line}"
        end
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
