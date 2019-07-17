# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class ScopeTest < Minitest::Test
  def test_minimal
    test_spec = load_fixture('minimal_scope')

    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)
  end
end
