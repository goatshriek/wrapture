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

    generated_files = Wrapture::CppWrapper.write_spec_files(scope)
    validate_wrapper_results(test_spec, generated_files)

    includes = get_include_list('Gym.hpp')
    assert_includes(includes, 'Pool.hpp')
    assert_includes(includes, 'Track.hpp')

    includes = get_include_list('Gym.cpp')
    assert_includes(includes, 'Pool.hpp')
    assert_includes(includes, 'Track.hpp')

    File.delete(*generated_files)
  end
end
