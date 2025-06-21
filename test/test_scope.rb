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
    test_spec = load_fixture('future_version_scope')

    assert_raises(Wrapture::UnsupportedSpecVersion) do
      Wrapture::Scope.new(test_spec)
    end
  end

  def test_minimal_scope
    test_spec = load_fixture('minimal_scope')
    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)
    assert_equal(0, scope.enums.count)

    build = Wrapture::CToCpp.wrap_scope(scope)

    assert_equal(scope.classes.count, build.sources.count / 2)
  end

  def test_nested_templates
    test_spec = load_fixture('scope_with_nested_templates')
    scope = Wrapture::Scope.new(test_spec)

    assert_equal(test_spec['classes'].count, scope.classes.count)
    assert_equal(0, scope.enums.count)

    build = Wrapture::CToCpp.wrap_scope(scope)

    assert_equal(scope.classes.count, build.sources.count / 2)
  end

  def test_templatized_classes
    spec_with_template = load_fixture('scope_with_template')
    scope = Wrapture::Scope.new(spec_with_template)
    with_template_build = Wrapture::CToCpp.wrap_scope(scope)

    spec_without_template = load_fixture('scope_without_template')
    scope = Wrapture::Scope.new(spec_without_template)
    no_template_build = Wrapture::CToCpp.wrap_scope(scope)

    with_template_build.sources.each do |with_src|
      assert_includes(no_template_build.sources, with_src,
                      "the build without templates is missing #{with_src}")
    end
  end

  def test_scope_with_enum
    test_spec = load_fixture('scope_with_enum')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    enum_name = test_spec['enums'][0]['name']
    header = build["#{enum_name}.hpp"]

    refute_nil(header)
    assert(source_file_contains_match?(header, enum_name))

    test_spec['enums'][0]['elements'].each do |element|
      assert(source_file_contains_match?(header, element['name']))
    end
  end

  def test_sequential_scope_load
    class_specs = [load_fixture('basic_class'),
                   load_fixture('child_class'),
                   load_fixture('constant_class'),
                   load_fixture('constructor_class')]
    enum_specs = [load_fixture('basic_enum')]
    scope = Wrapture::Scope.new
    class_specs.each { |spec| scope.add_class_spec_hash(spec) }
    enum_specs.each { |spec| scope.add_enum_spec_hash(spec) }

    assert_equal(class_specs.count, scope.classes.count)
    assert_equal(enum_specs.count, scope.enums.count)

    build = Wrapture::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    expected_count = (scope.classes.count * 2) + scope.enums.count

    assert_equal(expected_count, build.sources.count)
  end

  def test_versioned_scope
    test_spec = load_fixture('versioned_scope')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert_equal(test_spec['classes'].count, scope.classes.count)
    assert_equal(scope.classes.count, build.sources.count / 2)
  end
end
