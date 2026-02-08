# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025 Joel E. Anderson
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

class CToCppTest < Minitest::Test
  def test_basic_enum
    test_spec = fixture_hash('basic_enum')
    spec = Wrapture::EnumSpec.from_hash(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_enum(spec)

    validate_cpp_build(spec, build)

    assert_equal(test_spec[:name], spec.name)
    assert_equal(1, build.sources.count,
                 'only one file should have been generated')

    validate_cpp_source_file_matches_enum_spec(build.sources.first, test_spec)

    includes = get_source_file_include_list(build.sources.first)

    assert_includes(includes, 'overall_1.h')
    assert_includes(includes, 'overall_2.h')
    assert_includes(includes, 'val_1.h')
  end

  def test_class_pointer_to_struct_pointer
    test_spec = fixture_hash('scope_with_pointer_param')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert(source_file_contains_match?(build['Rifle.cpp'],
                                       /bullet->equivalent/),
           'equivalent struct member was not referenced')
  end

  def test_declaration_includes_with_no_c_details
    # we need a class spec where there isn't a :c key in wrapped
    class_spec = Wrapture::ClassSpec.new(fixture_hash('versioned_class'))

    assert_empty(Wrapture::Wrapper::CToCpp.declaration_includes(class_spec),
                 'declaration includes not empty for a class spec with no ' \
                 'entry for c in the wrapped languages')
  end

  def test_enum_with_namespace
    test_spec = fixture_hash('enum_with_namespace')
    spec = Wrapture::EnumSpec.from_hash(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_enum(spec)

    assert_equal(test_spec[:name], spec.name)
    assert_equal(1, build.sources.count,
                 'only one file should have been generated')

    validate_cpp_source_file_matches_enum_spec(build.sources.first, test_spec)
  end

  def test_from_language
    assert_equal(:c, Wrapture::Wrapper::CToCpp.from_language)
  end

  def test_reference_to_pointer
    test_spec = fixture_hash('scope_with_reference_param')
    scope = Wrapture::Scope.new(test_spec)
    build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)

    validate_cpp_build(scope, build)

    assert(source_file_contains_match?(build['Rifle.cpp'],
                                       /bullet\.equivalent/),
           'equivalent struct member was not referenced')
  end

  def test_to_language
    assert_equal(:cpp, Wrapture::Wrapper::CToCpp.to_language)
  end
end
