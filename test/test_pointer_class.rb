# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class ClassSpecTest < Minitest::Test
  def test_pointer_class
    test_spec = load_fixture('pointer_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    expected_signature = 'PointerWrappingClass\( struct wrapped_struct \*'
    assert(file_contains_match('PointerWrappingClass.hpp', expected_signature))

    File.delete(*classes)
  end
end
