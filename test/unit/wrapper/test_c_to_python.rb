# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2025-2026 Joel E. Anderson
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

class CToPythonTest < Minitest::Test
  def test_from_language
    assert_equal(:c, Wrapture::Wrapper::CToPython.from_language)
  end

  def test_includes
    hash = fixture_hash('basic_class')
    context = Wrapture::Context.from_class_hash(hash)
    source_set = Wrapture::Wrapper::CToPython.wrap_class_context(context)
    module_source = source_set['wrapture_test.c']

    refute_nil(module_source)
    assert_kind_of(Wrapture::CSource::CSourceFile, module_source)

    python_included = module_source.tree.any? do |it|
      it.is_a?(Wrapture::CSource::CInclude) && it.file == 'Python.h'
    end
    struct_included = module_source.tree.any? do |it|
      it.is_a?(Wrapture::CSource::CInclude) &&
        it.file == 'folder/include_file_1.h'
    end

    assert(python_included, 'Python.h was not included')
    assert(struct_included, 'the equivalent struct header was not included')
  end

  def test_multipart_scope_name
    scope = Wrapture::Scope.new({ name: %w[lots of parts] })
    wrapped_set = Wrapture::Wrapper::CToPython.wrap_scope(scope)

    assert_equal('lots_of_parts', wrapped_set.name)
  end

  def test_to_language
    assert_equal(:python, Wrapture::Wrapper::CToPython.to_language)
  end
end
