# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025 Joel E. Anderson
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
  module Wrapper
    # A collection of wrappers for generating C++ wrappers for C code.
    module CToCpp
      extend Wrapper

      # Returns a cast of the equivalent member of an instance of the given
      # class with the given name from one type to another.
      def self.cast_equivalent(class_spec, var_name, from, to)
        member_access = from.pointer? ? '->' : '.'
        struct = "struct #{class_spec.struct.name}"
        if [EQUIVALENT_STRUCT_KEYWORD, struct].include?(to)
          "#{if class_spec.pointer_wrapper?
               '*'
             end}#{var_name}#{member_access}equivalent"
        elsif [EQUIVALENT_POINTER_KEYWORD, "#{struct} *"].include?(to)
          "#{unless class_spec.pointer_wrapper?
               '&'
             end}#{var_name}#{member_access}equivalent"
        else
          raise "uncaught cast case: struct: '#{struct}', to '#{to}'"
        end
      end

      # Gives a code snippet that accesses the equivalent struct from
      # within the class using the given variable name.
      def self.class_struct(class_spec, var_name: 'this')
        name = "#{var_name}->equivalent"
        if class_spec.pointer_wrapper?
          "*(#{name})"
        else
          name
        end
      end

      # Gives a code snippet that accesses the equivalent struct pointer from
      # within the class using the given variable name.
      def self.class_struct_pointer(class_spec, var_name: 'this')
        name = "#{var_name}->equivalent"
        if class_spec.pointer_wrapper?
          name
        else
          "&(#{name})"
        end
      end

      # Generate a source file with the declaration of a class.
      def self.declare_class(class_spec)
        src = SourceFile.new("#{class_spec.name}.hpp")

        guard = header_guard(class_spec)
        src.puts("#ifndef #{guard}")
        src.puts("#define #{guard}")
        src.puts

        wrapper = CToCppWrapper.new(class_spec)
        wrapper.declare do |line|
          src.puts(line)
        end

        src.puts("#endif /* #{guard} */")

        src
      end

      # Generate a source file with the definition of a class.
      def self.define_class(class_spec)
        src = SourceFile.new("#{class_spec.name}.cpp")

        wrapper = CToCppWrapper.new(class_spec)
        wrapper.define do |line|
          src.puts(line)
        end

        src
      end

      # Generate a source file with the definition of an enumeration.
      def self.define_enum(enum_spec)
        src = SourceFile.new("#{enum_spec.name}.hpp")

        wrapper = CToCppWrapper.new(enum_spec)
        wrapper.define do |line|
          src.puts(line)
        end

        src
      end

      # The symbol to use for header guard checks.
      def self.header_guard(class_spec)
        "#{class_spec.screaming_snake_case_name}_HPP"
      end

      # True if the provided wrapped param spec can be cast to when used in this
      # function.
      def self.param_uses_equivalent?(func_spec, wrapped_param)
        param = func_spec.params.find { |p| p.name == wrapped_param.value }

        !param.nil? &&
          !wrapped_param.c_type.nil? &&
          func_spec.owner.type?(param.type)
      end

      # Gives an expression for using a given parameter.
      # Equivalent structs and pointers are resolved, as well as casts between
      # types if they are known within the scope of this function.
      def self.resolve_wrapped_param(func_spec, param)
        used_param = func_spec.params.find { |p| p.name == param.value }

        if param.value == EQUIVALENT_STRUCT_KEYWORD
          class_struct(func_spec.owner)
        elsif param.value == EQUIVALENT_POINTER_KEYWORD
          class_struct_pointer(func_spec.owner)
        elsif param.value == '...'
          'variadic_args'
        elsif param_uses_equivalent?(func_spec, param)
          param_class = func_spec.owner.type(used_param.type)
          from = used_param.type
          to = param.c_type.to_s
          cast_equivalent(param_class, used_param.name, from, to)
        else
          param.value
        end
      end

      # Generates a build for a C++ library wrapping a class.
      def self.wrap_class(class_spec)
        set = CppSource::CppSourceSet.new(class_spec.name)

        set.add_lib_header(declare_class(class_spec))
        set.add_lib_source(define_class(class_spec))

        class_spec.libraries.each do |lib|
          set.add_lib_link(lib)
        end

        set
      end

      # Generates a build for a C++ library wrapping the provided enum.
      def self.wrap_enum(enum_spec)
        build = CppSource::CppSourceSet.new(enum_spec.name)

        build.add_lib_header(define_enum(enum_spec))

        build
      end

      # Generates a build for a C++ library wrapping the provided scope.
      #
      # +scope+ describes all of the classes and other entities that will be
      # wrapped. These will all be put into a namespace named after the scope.
      def self.wrap_scope(scope)
        build = CppSource::CppSourceSet.new(scope.name)

        scope.each do |scope_member|
          build << wrap(scope_member)
        end

        build
      end
    end
  end
end
