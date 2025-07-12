# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class ConstantSpecTest < Minitest::Test
  def test_basic_new
    test_spec = fixture_hash('basic_constant')

    Wrapture::ConstantSpec.new(test_spec)
  end

  def test_future_spec_version
    test_spec = fixture_hash('future_version_constant')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::ConstantSpec.new(test_spec)
    end
  end

  def test_versioned_constant
    test_spec = fixture_hash('versioned_constant')

    Wrapture::ConstantSpec.new(test_spec)
  end
end
