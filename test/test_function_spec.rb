# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2020 Joel E. Anderson
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

    Wrapture::FunctionSpec.new(test_spec)
  end

  def test_documentation
    test_spec = load_fixture('documented_function')

    spec = Wrapture::FunctionSpec.new(test_spec)

    comment = String.new
    spec.declaration do |line|
      next if line.nil? || !line.lstrip.start_with?('/**', '*')

      comment << line << "\n"
    end

    refute(comment.empty?)
    assert(comment.include?('FunctionDocIdentifier'))
    assert(comment.include?('ParamDocIdentifier'))
    assert(comment.include?('ReturnDocIdentifier'))
  end

  def test_exception_throwing_function
    test_spec = load_fixture('exception_throwing_function')

    spec = Wrapture::FunctionSpec.new(test_spec)

    throw_code = 'throw CodeException( return_val )'
    spec.definition('NoSuchClass') do |line|
      next if line.nil?

      code = line.strip

      assert(code.include?(throw_code)) if code.start_with?('throw')
    end
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
    spec.definition('NoSuchClass') do |line|
      code = line.strip

      assert(code.start_with?("return #{call}")) if code.start_with?('return')
    end
  end

  def test_only_documented_params
    test_spec = load_fixture('documented_params')

    spec = Wrapture::FunctionSpec.new(test_spec)

    comment = String.new
    spec.declaration do |line|
      next if line.nil? || !line.lstrip.start_with?('/**', '*')

      refute_match(/^\s*\*\s*$/, line)
      comment << line << "\n"
    end

    refute(comment.empty?)
    assert(comment.include?('ParamDocIdentifier'))
  end

  def test_only_variadic_param
    test_spec = load_fixture('invalid/only_variadic_param')

    error = assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::FunctionSpec.new(test_spec)
    end

    assert(error.message.include?('only param'))
  end

  def test_variadic_functions
    test_specs = load_fixture('variadic_functions')

    test_specs.each do |test_spec|
      spec = Wrapture::FunctionSpec.new(test_spec)

      spec.declaration do |line|
        assert(line.include?('...'))
      end

      assert(spec.definition_includes.include?('stdarg.h'))

      spec.definition('NoSuchClass') do |line|
        code = line.strip

        assert(code.include?('variadic_args')) if code.include?('underlying')
      end
    end
  end

  def test_versioned_function
    test_spec = load_fixture('versioned_function')

    Wrapture::FunctionSpec.new(test_spec)
  end
end
