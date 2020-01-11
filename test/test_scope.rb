# frozen_string_literal: true

require 'helper'

require 'fixture'
require 'minitest/autorun'
require 'wrapture'

class ScopeTest < Minitest::Test
  def test_future_scope_version
    test_spec = load_fixture('future_version_scope')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_minimal_scope
    test_spec = load_fixture('minimal_scope')

    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)

    generated_files = scope.generate_wrappers
    assert_equal(scope.classes.count, generated_files.count / 2)

    File.delete(*generated_files)
  end

  def test_templatized_classes
    spec_with_template = load_fixture('scope_with_template')
    scope_with_template = Wrapture::Scope.new(spec_with_template)
    with_template_files = scope_with_template.generate_wrappers
    validate_wrapper_results(spec_with_template, with_template_files)

    # rename the files so that they don't overwrite one another
    with_template_files.each { |name| File.rename(name, "#{name}.with") }

    spec_without_template = load_fixture('scope_without_template')
    scope_without_template = Wrapture::Scope.new(spec_without_template)
    without_template_files = scope_without_template.generate_wrappers
    validate_wrapper_results(spec_without_template, without_template_files)

    # rename the second round of files for consistency
    without_template_files.each { |name| File.rename(name, "#{name}.without") }

    # the same filenames should have been generated
    assert_equal(with_template_files, without_template_files)

    # each of the files should be identical
    with_template_files.each do |name|
      assert(FileUtils.compare_files("#{name}.with", "#{name}.without"))
      File.delete("#{name}.with", "#{name}.without")
    end
  end

  def test_versioned_scope
    test_spec = load_fixture('versioned_scope')

    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)

    generated_files = scope.generate_wrappers
    assert_equal(scope.classes.count, generated_files.count / 2)

    File.delete(*generated_files)
  end
end
