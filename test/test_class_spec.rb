# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
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

  def test_class_with_constructor
    test_spec = load_fixture('constructor_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers

    refute_nil classes
    refute_empty classes
    assert classes.length == 2
    assert classes.include? "#{test_spec['name']}.cpp"
    assert classes.include? "#{test_spec['name']}.hpp"

    File.delete(*classes)
  end

  def test_class_with_constant
    test_spec = load_fixture('constant_class')

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
