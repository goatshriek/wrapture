# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class FunctionSpecTest < Minitest::Test
  def test_basic_new
    test_spec = load_fixture('basic_function')

    Wrapture::FunctionSpec.new(test_spec)
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

  def test_versioned_function
    test_spec = load_fixture('versioned_function')

    Wrapture::FunctionSpec.new(test_spec)
  end
end
