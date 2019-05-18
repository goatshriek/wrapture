# frozen_string_literal: true

module Wrapture

  ##
  # A description of a class, including its constants, functions, and other
  # details.
  class ClassSpec
    def initialize(spec)
      @spec = ClassSpec.normalize_spec_hash(spec)
    end

    def generate_wrappers
      files = []

      files << generate_declaration_file
      files << generate_definition_file
    end

    def self.normalize_spec_hash(spec)
      normalized_spec = spec.dup
      normalized_spec.default = []

      normalized_spec['equivalent-struct']['members'] ||= []

      normalized_spec['functions'].each do |function_spec|
        function_spec['params'] ||= []
        function_spec['wrapped-function']['params'] ||= []

        if function_spec['return'].nil?
          function_spec['return'] = {}
          function_spec['return']['type'] = 'void'
        end

        function_spec['return']['includes'] ||= []
      end

      normalized_spec['constants'].each do |constant_spec|
        constant_spec['includes'] ||= []
      end

      normalized_spec
    end

    private

    def header_guard
      "__#{@spec['name'].upcase}_HPP"
    end

    def declaration_includes
      includes = []

      includes.concat @spec['equivalent-struct']['includes']

      @spec['functions'].each do |function_spec|
        includes.concat function_spec['return']['includes']
      end

      includes.uniq
    end

    def definition_includes
      includes = ["#{@spec['name']}.hpp"]

      @spec['functions'].each do |function_spec|
        includes.concat function_spec['return']['includes']
        includes.concat function_spec['wrapped-function']['includes']
      end

      @spec['constants'].each do |constant_spec|
        includes.concat constant_spec['includes']
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

    def typed_variable(type, name)
      if type.end_with? '*'
        "#{type}#{name}"
      else
        "#{type} #{name}"
      end
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

    def function_signature_prefix(func_spec)
      modifier_prefix = if func_spec['static']
                          'static '
                        else
                          ''
                        end

      "#{modifier_prefix}#{func_spec['return']['type']}"
    end

    def function_param_list(function_spec)
      return 'void' if function_spec['params'].empty?

      params = []

      function_spec['params'].each do |param|
        params << typed_variable(param['type'], param['name'])
      end

      params.join ', '
    end

    def wrapped_function_call(function_spec)
      params = []

      function_spec['params'].each do |param|
        params << case param['name']
                  when 'equivalent-struct'
                    equivalent_struct
                  when 'equivalent-struct-pointer'
                    equivalent_struct_pointer
                  else
                    param['name']
                  end
      end

      "#{function_spec['name']}( #{params.join ', '} )"
    end

    def wrapped_constructor_signature(index)
      function_spec = @spec['constructors'][index]['wrapped-function']

      "#{@spec['name']}( #{function_param_list(function_spec)} )"
    end

    def destructor_signature
      "~#{@spec['name']}( void )"
    end

    def wrapped_function_signature(index)
      spec = @spec['functions'][index]

      "#{spec['name']}( #{function_param_list(spec)} )"
    end

    def wrapped_constructor_definition(index)
      constructor_spec = @spec['constructors'][index]
      wrapped_function = constructor_spec['wrapped-function']

      yield "#{@spec['name']}::#{wrapped_constructor_signature(index)}{"

      result = case wrapped_function['return']['type']
               when 'equivalent-struct'
                 equivalent_struct
               when 'equivalent-struct-pointer'
                 equivalent_struct_pointer
               end

      yield "  #{result} = #{wrapped_function_call wrapped_function};"

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

      file.puts unless @spec['constants'].empty?
      @spec['constants'].each do |spec|
        type_and_name = typed_variable(spec['type'], spec['name'])
        file.puts "    static const #{type_and_name};"
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

      @spec['functions'].each_index do |func|
        func_spec = @spec['functions'][func]
        prefix = function_signature_prefix func_spec
        signature = wrapped_function_signature func
        file.puts "    #{prefix} #{signature};"
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

      file.puts unless @spec['constants'].empty?
      @spec['constants'].each do |spec|
        const_decl = "const #{spec['type']} #{@spec['name']}::#{spec['name']}"
        file.puts "  #{const_decl} = #{spec['value']};"
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
        file.puts "    #{wrapped_function_call func_spec};"
        file.puts '  }'
      end

      @spec['functions'].each_index do |func|
        func_spec = @spec['functions'][func]

        file.puts

        return_type = func_spec['return']['type']
        signature = wrapped_function_signature func
        file.puts "  #{return_type} #{@spec['name']}::#{signature} {"

        wrapped_call = String.new
        wrapped_call << '    '
        wrapped_call << "return #{return_type} ( " unless return_type == 'void'
        wrapped_call << wrapped_function_call(func_spec['wrapped-function'])
        wrapped_call << ' )' unless return_type == 'void'
        wrapped_call << ';'

        file.puts wrapped_call
        file.puts '  }'
      end

      file.puts
      file.puts '}' # end of namespace

      file.close

      filename
    end
  end
end
