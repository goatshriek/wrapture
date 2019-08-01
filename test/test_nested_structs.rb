# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class NestedStructsTest < Minitest::Test
  def test_nested_structs
    test_spec = load_fixture('nested_structs')

    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)

    generated_files = scope.generate_wrappers
    assert_equal(scope.classes.count, generated_files.count / 2)

    File.delete(*generated_files)
  end
end
