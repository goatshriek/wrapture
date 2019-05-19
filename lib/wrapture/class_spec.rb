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

    def function_call(name, params)
      resolved_params = []

      params.each do |param|
        resolved_params << resolve_param(param['name'])
      end

      "#{name}( #{resolved_params.join ', '} )"
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
        includes.concat const.definition_includes
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

      "#{@spec['name']}( #{function_param_list(function_spec)} )"
    end

    def destructor_signature
      "~#{@spec['name']}( void )"
    end

    def wrapped_constructor_definition(index)
      constructor_spec = @spec['constructors'][index]
      wrapped_function = constructor_spec['wrapped-function']

      yield "#{@spec['name']}::#{wrapped_constructor_signature(index)}{"

      result = resolve_param wrapped_function['return']['type']

      yield "  #{result} = #{FunctionSpec.function_call wrapped_function};"

      yield '}'
    end

    def member_constructor_signature
      params = []

      @spec['equivalent-struct']['members'].each do |member|
        params << typed_variable(member['type'], member['name'])
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

      file = File.open(filename, 'w')

      file.puts "#ifndef #{header_guard}"
      file.puts "#define #{header_guard}"

      file.puts unless declaration_includes.empty?
      declaration_includes.each do |include_file|
        file.puts "#include <#{include_file}>"
      end

      file.puts
      file.puts "namespace #{@spec['namespace']} {"
      file.puts
      file.puts "  class #{@spec['name']} {"
      file.puts '  public:'

      file.puts unless @constants.empty?
      @constants.each do |const|
        file.puts "  #{const.declaration};"
      end

      file.puts
      struct_name = @spec['equivalent-struct']['name']
      file.puts "    struct #{struct_name} #{equivalent_name};"
      file.puts

      unless @spec['equivalent-struct']['members'].empty?
        file.puts "    #{member_constructor_signature};"
      end

      unless pointer_wrapper?
        file.puts "    #{struct_constructor_signature};"
        file.puts "    #{pointer_constructor_signature};"
      end

      @spec['constructors'].each_index do |constructor|
        file.puts "    #{wrapped_constructor_signature constructor};"
      end

      file.puts "    #{destructor_signature};" if @spec.key? 'destructor'

      @functions.each do |func|
        file.puts "    #{func.signature};"
      end

      file.puts '  };' # end of class
      file.puts
      file.puts '}' # end of namespace
      file.puts
      file.puts '#endif' # end of header guard

      file.close

      filename
    end

    def generate_definition_file
      filename = "#{@spec['name']}.cpp"

      file = File.open(filename, 'w')

      definition_includes.each do |include_file|
        file.puts "#include <#{include_file}>"
      end

      file.puts
      file.puts "namespace #{@spec['namespace']} {"

      file.puts unless @constants.empty?
      @constants.each do |const|
        file.puts "  #{const.definition};"
      end

      unless @spec['equivalent-struct']['members'].empty?
        file.puts
        file.puts "  #{@spec['name']}::#{member_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          member_decl = equivalent_member member['name']
          file.puts "    #{member_decl} = #{member['name']};"
        end

        file.puts '  }'
      end

      unless pointer_wrapper?
        file.puts
        file.puts "  #{@spec['name']}::#{struct_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          member_decl = equivalent_member member['name']
          file.puts "    #{member_decl} = equivalent.#{member['name']};"
        end

        file.puts '  }'

        file.puts
        file.puts "  #{@spec['name']}::#{pointer_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          member_decl = equivalent_member member['name']
          file.puts "    #{member_decl} = equivalent->#{member['name']};"
        end

        file.puts '  }'
      end

      @spec['constructors'].each_index do |constructor|
        file.puts
        wrapped_constructor_definition(constructor) do |line|
          file.puts "  #{line}"
        end
      end

      if @spec.key? 'destructor'
        file.puts
        file.puts "  #{@spec['name']}::#{destructor_signature} {"
        func_spec = @spec['destructor']['wrapped-function']
        file.puts "    #{function_call func_spec['name'], func_spec['params']};"
        file.puts '  }'
      end

      @functions.each do |func|
        file.puts

        func.definition(@spec['name']) do |def_line|
          file.puts "  #{def_line}"
        end
      end

      file.puts
      file.puts '}' # end of namespace

      file.close

      filename
    end
  end
end
