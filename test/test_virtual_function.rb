# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class FunctionSpecTest < Minitest::Test
  def test_class_with_virtual_function
    test_spec = load_fixture('class_with_virtual_function')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_virtual_function
    test_spec = load_fixture('virtual_function')

    func_spec = Wrapture::FunctionSpec.new(test_spec)
    assert(func_spec.virtual?)
  end
end
