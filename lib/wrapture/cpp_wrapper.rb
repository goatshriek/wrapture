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

      yield "    #{factory_declaration}" if @spec.factory?

      @spec.functions.each do |function|
        function.declaration { |line| yield "    #{line}" }
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
    def declare_function
      yield 'line 1'
      yield 'line 2'
      yield 'line 3'
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

    # The declaration of the factory function for this class which generates
    # instances of children classes based on a given struct.
    def factory_declaration
      param = @spec.struct.pointer_declaration('equivalent')
      "static #{@spec.name} *new#{@spec.name}( #{param} );"
    end
  end
end
