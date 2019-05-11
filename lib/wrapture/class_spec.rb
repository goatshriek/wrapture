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

    def pointer_wrapper?
      @spec['constructors'].each do |constructor_spec|
        return_type = constructor_spec['wrapped-function']['return']['type']

        return true if return_type == 'equivalent-struct-pointer'
      end

      false
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

    def function_param_list(function_spec)
      params = []
      function_spec['params'].each do |param|
        params << "#{param['type']} #{param['name']}"
      end
      params.join ', '
    end

    def wrapped_constructor_signature(index)
      function_spec = @spec['constructors'][index]['wrapped-function']

      "#{@spec['name']}( #{function_param_list(function_spec)} )"
    end

    def wrapped_function_signature(index)
      spec = @spec['functions'][index]

      "#{spec['name']}( #{function_param_list(spec)} )"
    end

    def wrapped_constructor_definition(index)
      constructor_spec = @spec['constructors'][index]
      wrapped_function = constructor_spec['wrapped-function']

      yield "#{@spec['name']}::#{wrapped_constructor_signature}{"

      result = case wrapped_function['return']['type']
               when 'equivalent-struct'
                 equivalent_struct
               when 'equivalent-struct-pointer'
                 equivalent_struct_pointer
               end

      param_list = function_param_list(wrapped_function)
      yield "  #{result} = #{wrapped_function['name']}( #{param_list} );"

      yield '}'
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
        file.puts "    static const #{spec['type']} #{spec['name']}"
      end

      file.puts
      struct_name = @spec['equivalent-struct']['name']
      file.puts "    struct #{struct_name} #{equivalent_name};"
      file.puts

      @spec['constructors'].each_index do |constructor|
        file.puts "    #{wrapped_constructor_signature(constructor)};"
      end

      unless @spec['destructor'].nil?
        file.puts "    ~#{@spec['name']}( void );"
      end

      @spec['functions'].each_index do |func|
        file.puts "    #{wrapped_function_signature(func)};"
      end

      file.puts '  };' # end of class
      file.puts '}' # end of namespace

      file.close
    end

    def generate_definition_file
      file = File.open("#{@spec['name']}.cpp", 'w')
      file.puts
      file.close
    end
  end
end
