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

  def test_rule_missing_condition
    test_spec = load_fixture('invalid/rule_missing_condition')

    assert_raises(Wrapture::MissingSpecKey) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_rule_with_invalid_condition
    test_spec = load_fixture('invalid/rule_with_invalid_condition')

    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_rule_with_invalid_key
    test_spec = load_fixture('invalid/rule_with_invalid_key')

    assert_raises(Wrapture::InvalidSpecKey) do
      Wrapture::Scope.new(test_spec)
    end
  end
end
