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

  def test_future_spec_version
    test_spec = load_fixture('future_version_class')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::ClassSpec.new(test_spec)
    end
  end

  def test_generate_wrappers
    test_spec = load_fixture('basic_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_child_class
    test_spec = load_fixture('child_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_class_with_constructor
    test_spec = load_fixture('constructor_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    source_file = "#{test_spec['name']}.cpp"
    includes = get_include_list(source_file)
    wrapped_function = test_spec['constructors'][0]['wrapped-function']
    assert_includes(includes, wrapped_function['includes'])

    forbidden = Wrapture::EQUIVALENT_STRUCT_KEYWORD
    assert(!file_contains_match(source_file, forbidden))

    assert(file_contains_match(source_file, /= #{wrapped_function['name']}/))

    File.delete(*classes)
  end

  def test_class_with_constant
    test_spec = load_fixture('constant_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_class_with_static_function
    test_spec = load_fixture('static_function_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    static_function_found = false
    File.open("#{test_spec['name']}.hpp", 'r').each do |line|
      static_function_found = true if line.include? 'static'
    end
    assert static_function_found, 'No static function defined.'

    File.delete(*classes)
  end

  def test_default_constructor_generation
    test_spec = load_fixture('default_value_members')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)
    assert(file_contains_match("DefaultMembersClass.hpp", "member_1 = 42"))

    File.delete(*classes)
  end

  def test_versioned_class
    test_spec = load_fixture('versioned_class')

    spec = Wrapture::ClassSpec.new(test_spec)

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end

  def test_wrapper_class
    test_spec = load_fixture('struct_wrapper_class')

    spec = Wrapture::ClassSpec.new test_spec

    classes = spec.generate_wrappers
    validate_wrapper_results(test_spec, classes)

    File.delete(*classes)
  end
end
