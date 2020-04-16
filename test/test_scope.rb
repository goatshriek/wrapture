# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2020 Joel E. Anderson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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

  def test_nested_templates
    test_spec = load_fixture('scope_with_nested_templates')

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

    # rename the files so that they don't overwrite one another
    with_template_files.each { |name| File.rename(name, "#{name}.with") }

    spec_without_template = load_fixture('scope_without_template')
    scope_without_template = Wrapture::Scope.new(spec_without_template)
    without_template_files = scope_without_template.generate_wrappers

    # rename the second round of files for consistency
    without_template_files.each { |name| File.rename(name, "#{name}.without") }

    # the same filenames should have been generated
    assert_equal(with_template_files, without_template_files)

    # each of the files should be identical
    with_template_files.each do |name|
      assert(FileUtils.compare_file("#{name}.with", "#{name}.without"))
      File.delete("#{name}.with", "#{name}.without")
    end
  end

  def test_scope_with_enum
    test_spec = load_fixture('scope_with_enum')

    scope = Wrapture::Scope.new(test_spec)

    generated_files = scope.generate_wrappers

    enum_name = test_spec['enums'][0]['name']
    enum_filename = "#{enum_name}.hpp"

    assert(FileTest.exist?(enum_filename),
           "enum file '#{enum_filename}' was not created")
    assert(file_contains_match(enum_filename, enum_name))

    test_spec['enums'][0]['elements'].each do |element|
      assert(file_contains_match(enum_filename, element['name']))
    end

    File.delete(*generated_files)
  end

  def test_sequential_scope_load
    class_specs = [load_fixture('basic_class'),
                   load_fixture('child_class'),
                   load_fixture('constant_class'),
                   load_fixture('constructor_class')]
    enum_specs = [load_fixture('basic_enum')]

    scope = Wrapture::Scope.new

    class_specs.each { |spec| scope.add_class_spec_hash(spec) }
    assert_equal(class_specs.count, scope.classes.count)

    enum_specs.each { |spec| scope.add_enum_spec_hash(spec) }
    assert_equal(enum_specs.count, scope.enums.count)

    generated_files = scope.generate_wrappers
    expected_count = scope.classes.count * 2 + scope.enums.count
    assert_equal(expected_count, generated_files.count)

    File.delete(*generated_files)
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
