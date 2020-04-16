# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020 Joel E. Anderson
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
  # A description of an enumeration.
  class EnumSpec
    # Returns a normalized copy of a hash specification of an enumeration in
    # place. See normalize_spec_hash! for details.
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes a hash specification of an enumeration in place. Normalization
    # will remove duplicate entries in include lists and check for a name key.
    def self.normalize_spec_hash!(spec)
      unless spec.key?('name')
        raise MissingSpecKey, 'a name is required for enumerations'
      end

      if spec.key?('elements')
        unless spec['elements'].is_a?(Array)
          raise InvalidSpecKey, 'the elements key must be an array'
        end
      else
        raise MissingSpecKey, 'elements are required for enumerations'
      end

      spec['includes'] = Wrapture.normalize_includes(spec['includes'])
      spec['elements'].each do |element|
        element['includes'] = Wrapture.normalize_includes(element['includes'])
      end

      spec
    end

    # Creates an enumeration specification based on the provided hash spec.
    def initialize(spec)
      @spec = EnumSpec.normalize_spec_hash(spec)

      @doc = Comment.new(@spec.fetch('doc', nil))
    end

    # Generates the wrapper definition file.
    def generate_wrapper
      filename = "#{@spec['name']}.hpp"

      File.open(filename, 'w') do |file|
        definition_contents do |line|
          file.puts(line)
        end
      end

      [filename]
    end

    # The name of the enumeration.
    def name
      @spec['name']
    end

    private

    # Yields each line of the definition of the wrapper for this enum.
    def definition_contents
      indent = 0

      yield "#ifndef #{header_guard}"
      yield "#define #{header_guard}"
      yield

      definition_includes.each { |filename| yield "#include <#{filename}>" }
      yield

      if @spec.key?('namespace')
        yield "namespace #{@spec['namespace']} {"
        yield
        indent += 2
      end

      @doc.format_as_doxygen(max_line_length: 76) do |line|
        yield "#{' ' * indent}#{line}"
      end

      yield "#{' ' * indent}enum class #{name} {"
      indent += 2

      elements = @spec['elements']
      elements[0...-1].each do |element|
        element_doc(element) { |line| yield "#{' ' * indent}#{line}" }
        element_definition(element) { |line| yield "#{' ' * indent}#{line}," }
      end

      element_doc(elements.last) { |line| yield "#{' ' * indent}#{line}" }
      element_definition(elements.last) do |line|
        yield "#{' ' * indent}#{line}"
      end

      indent -= 2
      yield "#{' ' * indent}};"
      yield
      yield '}' if @spec.key?('namespace')
      yield
      yield "#endif /* #{header_guard} */"
    end

    # A list of the includes needed for the definition of the enumeration.
    def definition_includes
      includes = @spec['includes'].dup

      @spec['elements'].each do |element|
        includes.concat(element['includes'])
      end

      includes.uniq
    end

    # Yields each line of the definition of an element.
    def element_definition(element)
      if element.key?('value')
        yield "#{element['name']} = #{element['value']}"
      else
        yield element['name']
      end
    end

    # Yields each line of the documentation for an element.
    def element_doc(element)
      doc = Comment.new(element.fetch('doc', nil))
      doc.format_as_doxygen(max_line_length: 74) { |line| yield line }
    end

    # The header guard for the enumeration.
    def header_guard
      "__#{@spec['name'].upcase}_HPP"
    end
  end
end
