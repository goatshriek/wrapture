# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2025 Joel E. Anderson
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
    test_spec = fixture_hash('future_version_scope')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_minimal_scope
    test_spec = fixture_hash('minimal_scope')
    scope = Wrapture::Scope.new(test_spec)

    assert_predicate(scope, :definable?)
    assert_equal(test_spec[:classes].count, scope.classes.count)
    assert_equal(0, scope.enums.count)

    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    assert_equal(scope.classes.count, build.sources.count / 2)
    assert_equal('wrapture_test', scope.name)
  end

  def test_nested_templates
    test_spec = fixture_hash('scope_with_nested_templates')
    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec[:classes].count, scope.classes.count)
    assert_equal(0, scope.enums.count)

    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    assert_equal(scope.classes.count, build.sources.count / 2)
  end

  def test_templatized_classes
    spec_with_template = fixture_hash('scope_with_template')
    scope = Wrapture::Scope.new(spec_with_template)
    with_template_build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    spec_without_template = fixture_hash('scope_without_template')
    scope = Wrapture::Scope.new(spec_without_template)
    no_template_build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    assert_equal(with_template_build.sources.first.path,
                 no_template_build.sources.first.path)
    assert_equal(with_template_build.sources.first.contents,
                 no_template_build.sources.first.contents)
    assert_equal(with_template_build.sources.first,
                 no_template_build.sources.first)

    with_template_build.sources.each do |with_src|
      # puts with_src.hash
      # puts with_src.class

      # no_template_build.sources.each do |without_src|
      #   puts without_src.hash
      #   puts without_src.class
      # end

      # puts no_template_build.class
      # puts no_template_build.sources.class
      # puts no_template_build.include?(with_src)

      assert_includes(no_template_build, with_src,
                      "the build without templates is missing #{with_src}")
    end
  end

  def test_scope_with_enum
    test_spec = fixture_hash('scope_with_enum')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)
    enum_name = test_spec[:enums][0][:name]
    header_name = "#{enum_name}.hpp"

    assert_includes(build, header_name)
    header = build[header_name]

    refute_nil(header)
    test_spec[:enums][0][:elements].each do |element|
      assert(source_file_contains_match?(header, element[:name]))
    end
  end

  def test_sequential_scope_load
    class_specs = [fixture_hash('basic_class'),
                   fixture_hash('child_class'),
                   fixture_hash('constant_class'),
                   fixture_hash('constructor_class')]
    enum_specs = [fixture_hash('basic_enum')]
    scope = Wrapture::Scope.new
    class_specs.each { |spec| scope.add_class_spec_hash(spec) }
    enum_specs.each { |spec| scope.add_enum_spec_hash(spec) }

    assert_equal(class_specs.count, scope.classes.count)
    assert_equal(enum_specs.count, scope.enums.count)

    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    expected_count = (scope.classes.count * 2) + scope.enums.count

    assert_equal(expected_count, build.sources.count)
  end

  def test_undefinable_scope
    spec_hash = fixture_hash('undefinable_class')
    class_spec = Wrapture::ClassSpec.new(spec_hash)

    refute_predicate(class_spec.scope, :definable?)
  end

  def test_versioned_scope
    test_spec = fixture_hash('versioned_scope')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert_equal(test_spec[:classes].count, scope.classes.count)
    assert_equal(scope.classes.count, build.sources.count / 2)
  end
end
