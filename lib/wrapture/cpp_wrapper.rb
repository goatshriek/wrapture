# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021 Joel E. Anderson
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
  # A wrapper that generates C++ wrappers for given specs.
  class CppWrapper
    # Gives each line of the declaration of a spec to the provided block
    # This is equivalent to instantiating a wrapper with the given spec, and
    # then calling declare on that.
    def self.declare_spec(spec, &block)
      wrapper = new(spec)
      wrapper.declare(&block)
    end

    # Gives each line of the definition of a spec to the provided block
    # This is equivalent to instantiating a wrapper with the given spec, and
    # then calling define on that.
    def self.define_spec(spec, &block)
      wrapper = new(spec)
      wrapper.define(&block)
    end

    # Generates C++ source files, returning a list of the files generated. This
    # is equivalent to instantiating a wrapper with the given spec, and then
    # calling write_files on that.
    def self.write_spec_files(spec, **kwargs)
      wrapper = new(spec)
      wrapper.write_files(**kwargs)
    end

    # Creates a wrapper for a given spec.
    def initialize(spec)
      @spec = spec
    end

    # Gives a list of ancestor classes of class spec, including a colon prefix,
    # if the class has ancestors. If not or if this wrapper is not for a class,
    # an empty string is returned instead.
    def ancestor_suffix
      if @spec.is_a?(ClassSpec) && @spec.child?
        ": public #{@spec.parent_name}"
      else
        ''
      end
    end

    # Gives each line of the declaration to the provided block.
    def declare(&block)
      case @spec
      when ClassSpec
        declare_class(&block)
      when FunctionSpec
        declare_function(&block)
      end
    end

    # Gives each line of the definition to the provided block.
    def define(&block)
      case @spec
      when ClassSpec
        define_class(&block)
      when EnumSpec
        define_enum(&block)
      when FunctionSpec
        define_function(&block)
      end
    end

    # Gives the symbol to use for header guard checks.
    def header_guard
      "#{@spec.name.upcase}_HPP"
    end

    # Generates the C++ declaration file, returning the name of the file
    # generated.
    # +dir+ specifies the directory that the file should be written into. The
    # default is the current working directory.
    def write_declaration_file(dir: Dir.pwd)
      filename = "#{@spec.name}.hpp"

      File.open(File.join(dir, filename), 'w') do |file|
        declare { |line| file.puts(line) }
      end

      filename
    end

    # Generates the C++ definition file, returning the name of the file
    # generated.
    # +dir+ specifies the directory that the file should be written into. The
    # default is the current working directory.
    def write_definition_file(dir: Dir.pwd)
      filename = if @spec.is_a?(EnumSpec)
                   "#{@spec.name}.hpp"
                 else
                   "#{@spec.name}.cpp"
                 end

      File.open(File.join(dir, filename), 'w') do |file|
        @spec.definition_contents { |line| file.puts(line) }
      end

      filename
    end

    # Generates C++ source files, returning a list of the files generated.
    # +dir+ specifies the directory that the files should be written into. The
    # default is the current working directory.
    def write_files(dir: Dir.pwd)
      case @spec
      when Scope
        (@spec.classes + @spec.enums).flat_map do |item|
          self.class.write_spec_files(item, dir: dir)
        end
      when EnumSpec
        [write_definition_file(dir: dir)]
      else
        [write_declaration_file(dir: dir),
         write_definition_file(dir: dir)]
      end
    end

    private

    # Returns a list of FunctionSpecs describing all of the functions generated
    # for a ClassSpec. This includes both those listed in the original
    # ClassSpec, as well as those auto-generated by the library.
    def class_functions
      functions = @spec.functions.dup

      if @spec.struct
        spec_hash = { 'name' => @spec.name,
                      'params' => [{ 'name' => 'equivalent',
                                     'type' => 'equivalent-struct-pointer' }],
                      'wrapped-code' => { 'lines' => %w[1 2 3] },
                      'return' => { 'type' => 'equivalent-struct-pointer' } }
        functions << FunctionSpec.new(spec_hash, @spec, constructor: true)
      end

      if @spec.struct&.members?
        spec_hash = { 'name' => @spec.name,
                      'params' => @spec.struct.members,
                      'wrapped-code' => { 'lines' => %w[1 2 3] },
                      'return' => { 'type' => 'equivalent-struct-pointer' } }
        functions << FunctionSpec.new(spec_hash, @spec, constructor: true)
      end

      if @spec.factory?
        spec_hash = { 'name' => "new#{@spec.name}",
                      'static' => true,
                      'params' => [{ 'name' => 'equivalent',
                                     'type' => 'equivalent-struct-pointer' }],
                      'wrapped-code' => { 'lines' => %w[1 2 3] },
                      'return' => { 'type' => 'equivalent-struct-pointer' } }
        functions << FunctionSpec.new(spec_hash, @spec, constructor: true)
      end

      functions
    end

    # Gives each line of the declaration of a ClassSpec to the provided block.
    def declare_class
      yield "#ifndef #{header_guard}"
      yield "#define #{header_guard}"
      yield ''

      unless @spec.declaration_includes.empty?
        @spec.declaration_includes.each { |inc| yield "#include <#{inc}>" }
        yield ''
      end

      yield "namespace #{@spec.namespace} {"
      yield ''

      @spec.documentation { |line| yield "  #{line}" }
      yield "  class #{@spec.name} #{ancestor_suffix}{"
      yield '  public:'

      unless @spec.constants.empty?
        @spec.constants.each do |constant|
          constant.declaration { |line| yield "    #{line}" }
        end
        yield ''
      end

      class_functions.each do |function|
        self.class.declare_spec(function) { |line| yield "    #{line}" }
      end

      if @spec.equivalent_member?
        yield ''
        yield "    #{equivalent_member_declaration}"
      end

      yield '  };' # end of class
      yield ''
      yield '}' # end of namespace
      yield ''
      yield "#endif /* #{header_guard} */"
    end

    # Gives each line of the declaration of a FunctionSpec to the provided
    # block.
    def declare_function(&block)
      @spec.doc.format_as_doxygen(max_line_length: 76) do |line|
        block.call(line)
      end

      modifier_prefix = if @spec.static?
                          'static '
                        elsif @spec.virtual?
                          'virtual '
                        else
                          ''
                        end

      block.call("#{modifier_prefix}#{@spec.return_expression};")
    end

    # Gives each line of the definition of a ClassSpec to the provided block.
    def define_class
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the definition of a EnumSpec to the provided block.
    def define_enum
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # Gives each line of the definition of a FunctionSpec to the provided
    # block.
    def define_function
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
    end

    # The declaration of the equivalent member of this class.
    def equivalent_member_declaration
      if @spec.pointer_wrapper?
        "#{@spec.struct.pointer_declaration('equivalent')};"
      else
        "#{@spec.struct.declaration('equivalent')};"
      end
    end
  end
end
