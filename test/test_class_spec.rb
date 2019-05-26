# frozen_string_literal: true

require 'fixture'
require 'minitest/autorun'
require 'helper'
require 'wrapture'

class ClassSpecTest < Minitest::Test
  def test_normalize
    test_spec = load_fixture('minimal_class')

    normalized_spec = Wrapture::ClassSpec.normalize_spec_hash test_spec

    refute_nil normalized_spec
  end

  def test_generate_wrappers
    test_spec = load_fixture('basic_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers

    refute_nil classes
    refute_empty classes
    assert classes.length == 2
    assert classes.include? "#{test_spec['name']}.cpp"
    assert classes.include? "#{test_spec['name']}.hpp"

    File.delete(*classes)
  end
end
