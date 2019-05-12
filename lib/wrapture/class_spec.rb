module Wrapture
  class ClassSpec
    def initialize(spec)
      @spec = ClassSpec.normalize_spec_hash(spec)
    end

    def generate_wrappers
      generate_declaration_file
      generate_definition_file
    end

    def self.normalize_spec_hash(spec)
      normalized_spec = spec.dup

      if normalized_spec['constructors'].nil?
        normalized_spec['constructors'] = []
      end

      if normalized_spec['equivalent-struct']['members'].nil?
        normalized_spec['equivalent-struct']['members'] = []
      end

      if normalized_spec['functions'].nil?
        normalized_spec['functions'] = []
      else
        normalized_spec['functions'].each do |function_spec|
          if function_spec['params'].nil?
            function_spec['params'] = []
          end

          if function_spec['wrapped-function']['params'].nil?
            function_spec['wrapped-function']['params'] = []
          end

          if function_spec['return'].nil?
            function_spec['return'] = {}
            function_spec['return']['type'] = 'void'
          end

          if function_spec['return']['includes'].nil?
            function_spec['return']['includes'] = []
          end
        end
      end

      if normalized_spec['constants'].nil?
        normalized_spec['constants'] = []

      else
        normalized_spec['constants'].each do |constant_spec|
          if constant_spec['includes'].nil?
            constant_spec['includes'] = []
          end
        end
      end

      return normalized_spec
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
        params << typed_variable( param['type'], param['name'])
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

      param_list = function_param_list(wrapped_function)
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
      "#{@spec['name']}( struct #{@spec['equivalent-struct']['name']} equivalent )"
    end

    def pointer_constructor_signature
      "#{@spec['name']}( struct #{@spec['equivalent-struct']['name']} *equivalent )"
    end

    def generate_declaration_file
      file = File.open("#{@spec['name']}.hpp", 'w')

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
        file.puts "    static const #{typed_variable(spec['type'], spec['name'])};"
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

      unless @spec['destructor'].nil?
        file.puts "    #{destructor_signature};"
      end

      @spec['functions'].each_index do |func|
        func_spec = @spec['functions'][func]
        file.puts "    #{function_signature_prefix func_spec} #{wrapped_function_signature func};"
      end

      file.puts '  };' # end of class
      file.puts
      file.puts '}' # end of namespace
      file.puts
      file.puts '#endif' # end of header guard

      file.close
    end

    def generate_definition_file
      file = File.open("#{@spec['name']}.cpp", 'w')

      definition_includes.each do |include_file|
        file.puts "#include <#{include_file}>"
      end

      file.puts
      file.puts "namespace #{@spec['namespace']} {"

      file.puts unless @spec['constants'].empty?
      @spec['constants'].each do |spec|
        file.puts "  const #{spec['type']} #{@spec['name']}::#{spec['name']} = #{spec['value']};"
      end

      unless @spec['equivalent-struct']['members'].empty?
        file.puts
        file.puts "  #{@spec['name']}::#{member_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          file.puts "    #{equivalent_member member['name']} = #{member['name']};"
        end

        file.puts '  }'
      end

      unless pointer_wrapper?
        file.puts
        file.puts "  #{@spec['name']}::#{struct_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          file.puts "    #{equivalent_member member['name']} = equivalent.#{member['name']};"
        end

        file.puts '  }'

        file.puts
        file.puts "  #{@spec['name']}::#{pointer_constructor_signature} {"

        @spec['equivalent-struct']['members'].each do |member|
          file.puts "    #{equivalent_member member['name']} = equivalent->#{member['name']};"
        end

        file.puts '  }'
      end

      @spec['constructors'].each_index do |constructor|
        file.puts
        wrapped_constructor_definition(constructor) do |line|
          file.puts "  #{line}"
        end
      end

      unless @spec['destructor'].nil?
        file.puts
        file.puts "  #{@spec['name']}::#{destructor_signature} {"
        file.puts "    #{wrapped_function_call @spec['destructor']['wrapped-function']};"
        file.puts '  }'
      end

      @spec['functions'].each_index do |func|
        func_spec = @spec['functions'][func]

        file.puts

        return_type = func_spec['return']['type']
        file.puts "  #{return_type} #{@spec['name']}::#{wrapped_function_signature func} {"

        wrapped_call = '    '

        unless return_type == 'void'
          wrapped_call << "return #{return_type} ( "
        end

        wrapped_call << "#{wrapped_function_call func_spec['wrapped-function']}"

        wrapped_call << ' )' unless return_type == 'void'
        wrapped_call << ';'

        file.puts wrapped_call
        file.puts '  }'
      end

      file.puts
      file.puts '}' # end of namespace

      file.close
    end
  end
end
