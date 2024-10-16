# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2021 Joel E. Anderson
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

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class FunctionSpecTest < Minitest::Test
  def test_basic_new
    test_spec = load_fixture('basic_function')

    spec = Wrapture::FunctionSpec.new(test_spec)
    code = Wrapture::CppWrapper.define_spec(spec, &block_collector)
    code = code.map(&:lstrip)

    refute_includes(code, 'return return_val;')
  end

  def test_documentation
    test_spec = load_fixture('documented_function')

    spec = Wrapture::FunctionSpec.new(test_spec)

    comment = String.new
    Wrapture::CppWrapper.declare_spec(spec) do |line|
      next if line.nil? || !line.lstrip.start_with?('/**', '*')

      comment << line << "\n"
    end

    refute_empty(comment)
    assert_includes(comment, 'FunctionDocIdentifier')
    assert_includes(comment, 'ParamDocIdentifier')
    assert_includes(comment, 'ReturnDocIdentifier')
  end

  def test_exception_throwing_function
    test_spec = load_fixture('exception_throwing_function')

    spec = Wrapture::FunctionSpec.new(test_spec)

    throw_code = 'throw CodeException( return_val )'
    Wrapture::CppWrapper.define_spec(spec) do |line|
      next if line.nil?

      code = line.strip

      assert_includes(code, throw_code) if code.start_with?('throw')
    end
  end

  def test_exception_without_return_val
    test_spec = load_fixture('exception_check_without_return_val')

    spec = Wrapture::FunctionSpec.new(test_spec)

    lines = Wrapture::CppWrapper.define_spec(spec, &block_collector)

    assert(lines.any? { |line| line.end_with?('int return_val;') })
    assert(lines.any? { |line| line.end_with?('return return_val;') })
  end

  def test_function_pointer_argument
    test_spec = load_fixture('function_pointer_argument')

    spec = Wrapture::FunctionSpec.new(test_spec)

    all_spec_includes(test_spec).each do |inc|
      assert_includes(spec.declaration_includes, inc)
      assert_includes(spec.definition_includes, inc)
    end

    arg_type = 'const char *( *my_func_ptr )( int, int, void * )'

    lines = Wrapture::CppWrapper.declare_spec(spec, &block_collector)

    assert(lines.any? { |line| line.include?(arg_type) })

    lines = Wrapture::CppWrapper.define_spec(spec, &block_collector)

    assert(lines.any? { |line| line.include?(arg_type) })
  end

  def test_function_pointer_return
    test_spec = load_fixture('function_pointer_return')

    spec = Wrapture::FunctionSpec.new(test_spec)

    all_spec_includes(test_spec).each do |inc|
      assert_includes(spec.declaration_includes, inc)
      assert_includes(spec.definition_includes, inc)
    end

    expected_declaration = 'const char *( *FunctionPointerReturn( const ' \
                           'char *my_string ) )( int, int, struct special * );'

    lines = Wrapture::CppWrapper.declare_spec(spec, &block_collector)

    assert(lines.any? { |line| line.include?(expected_declaration) })

    expected_definition = 'const char *( *FunctionPointerReturn( const ' \
                          'char *my_string ) )( int, int, struct special * ) {'

    lines = Wrapture::CppWrapper.define_spec(spec, &block_collector)

    assert(lines.any? { |line| line.include?(expected_definition) })
    refute(lines.any? { |line| line.include?('=>') },
           'a rocket operator was found in the output code')
  end

  def test_future_spec_version
    test_spec = load_fixture('future_version_function')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::FunctionSpec.new(test_spec)
    end
  end

  def test_matching_return_types
    test_spec = load_fixture('no_cast_function')

    spec = Wrapture::FunctionSpec.new(test_spec)

    call = test_spec['wrapped-function']['name']
    Wrapture::CppWrapper.define_spec(spec) do |line|
      code = line.strip

      assert(code.start_with?("return #{call}")) if code.start_with?('return')
    end
  end

  def test_nested_function_pointer_argument
    test_spec = load_fixture('nested_function_pointer_argument')

    spec = Wrapture::FunctionSpec.new(test_spec)

    expected_declaration = 'void NestedFunctionPointerArgument( const char ' \
                           '*( *my_func_ptr )( int, int ( * )( struct ' \
                           'special *, void * ), void * ) );'

    lines = Wrapture::CppWrapper.declare_spec(spec, &block_collector)

    assert(lines.any? { |line| line.include?(expected_declaration) })
  end

  def test_nested_function_pointer_return
    test_spec = load_fixture('nested_function_pointer_return')

    spec = Wrapture::FunctionSpec.new(test_spec)

    all_spec_includes(test_spec).each do |inc|
      assert_includes(spec.declaration_includes, inc)
      assert_includes(spec.definition_includes, inc)
    end

    expected_declaration = 'int ( *( *NestedFunctionPointerReturn( const ' \
                           'char *my_string ) )( int, int, void * ) )( ' \
                           'struct special *, int );'

    lines = Wrapture::CppWrapper.declare_spec(spec, &block_collector)

    assert(lines.any? { |line| line.include?(expected_declaration) })
  end

  def test_only_documented_params
    test_spec = load_fixture('documented_params')

    spec = Wrapture::FunctionSpec.new(test_spec)

    comment = String.new
    Wrapture::CppWrapper.declare_spec(spec) do |line|
      next if line.nil? || !line.lstrip.start_with?('/**', '*')

      refute_match(/^\s*\*\s*$/, line)
      comment << line << "\n"
    end

    refute_empty(comment)
    assert_includes(comment, 'ParamDocIdentifier')
  end

  def test_only_variadic_param
    test_spec = load_fixture('invalid/only_variadic_param')

    error = assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::FunctionSpec.new(test_spec)
    end

    assert_includes(error.message, 'only param')
  end

  def test_undefinable
    test_spec = load_fixture('undefinable_function')

    spec = Wrapture::FunctionSpec.new(test_spec)

    refute_predicate(spec, :definable?)

    assert_raises(Wrapture::UndefinableSpec) do
      Wrapture::CppWrapper.define_spec(spec) { flunk('unreachable') }
    end
  end

  def test_variadic_functions
    test_specs = load_fixture('variadic_functions')

    test_specs.each do |test_spec|
      spec = Wrapture::FunctionSpec.new(test_spec)

      Wrapture::CppWrapper.declare_spec(spec) do |line|
        assert_includes(line, '...')
      end

      # assert(spec.signature.end_with?('... )'))

      assert_includes(spec.definition_includes, 'stdarg.h')

      Wrapture::CppWrapper.define_spec(spec) do |line|
        code = line.strip

        assert_includes(code, 'variadic_args') if code.include?('underlying')
      end
    end
  end

  def test_versioned_function
    test_spec = load_fixture('versioned_function')

    Wrapture::FunctionSpec.new(test_spec)
  end
end
