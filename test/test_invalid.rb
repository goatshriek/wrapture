# frozen_string_literal: true

require 'helper'

require 'minitest/autorun'
require 'wrapture'

class InvalidTest < Minitest::Test
  def test_no_namespace
    test_spec = load_fixture 'invalid/no_namespace'

    assert_raises(Wrapture::WraptureError) do
      Wrapture::ClassSpec.new test_spec
    end
  end
end
