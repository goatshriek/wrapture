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
  def test_class_type_struct_with_child_class
    class_hash = fixture_hash('child_class')
    context = Wrapture::Context.from_class_hash(class_hash)
    type_struct = Wrapture::Wrapper::CToPython.class_type_struct(context)

    refute_nil(type_struct)
  end

  def test_class_type_struct_with_pointer_wrapper_class
    class_hash = fixture_hash('basic_class')
    context = Wrapture::Context.from_class_hash(class_hash)
    type_struct = Wrapture::Wrapper::CToPython.class_type_struct(context)
    expected_typedef = Wrapture::Wrapper::CToPython.type_struct_name(context)

    refute_nil(type_struct)
    assert_kind_of(Wrapture::CSource::CStruct, type_struct)
    assert_equal(expected_typedef, type_struct.typedef)
  end

  def test_from_language
    assert_equal(:c, Wrapture::Wrapper::CToPython.from_language)
  end

  def test_includes
    ns = Wrapture::Namespace.new(%w[basic module])
    ns_context = Wrapture::Context.new(ns)
    hash = fixture_hash('basic_class')
    class_context = Wrapture::Context.from_class_hash(hash, parent: ns_context)
    ns_context.contents << class_context
    source_set = Wrapture::Wrapper::CToPython.wrap_namespace_context(ns_context)

    refute_nil(source_set)
    refute_empty(source_set.sources, 'wrapper has no source files')

    module_source = source_set['basic_module.c']

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

  def test_multipart_namespace_name
    ns = Wrapture::Namespace.new(%w[lots of parts])
    context = Wrapture::Context.new(ns)
    wrapped_set = Wrapture::Wrapper::CToPython.wrap_namespace_context(context)

    assert_equal('lots_of_parts', wrapped_set.name)
  end

  def test_overload_groups_with_constructors
    context = Wrapture::Context.new(Wrapture::Namespace.new(%w[wrapture test]))
    class_hash = fixture_hash('class_with_overloaded_constructors')
    class_context = Wrapture::Context.from_class_hash(class_hash,
                                                      parent: context)
    context.contents << class_context
    groups = Wrapture::Wrapper::CToPython.overload_groups(context)

    refute_empty(groups)
  end

  def test_overloaded_constructors
    class_hash = fixture_hash('class_with_overloaded_constructors')
    context = Wrapture::Context.from_class_hash(class_hash)

    assert(Wrapture::Wrapper::CToPython.constructors_overloaded?(context))
  end

  def test_overloaded_constructors_with_only_member_constructor
    class_hash = fixture_hash('struct_wrapper_class')
    context = Wrapture::Context.from_class_hash(class_hash)

    refute(Wrapture::Wrapper::CToPython.constructors_overloaded?(context))
  end

  def test_parse_tuple_call
    ns_hash = fixture_hash('namespace_with_class_and_enum')
    context = Wrapture::Context.from_namespace_hash(ns_hash)
    func = context.classes.first.functions.first
    call = Wrapture::Wrapper::CToPython.parse_tuple_call(func)

    refute_nil(call)
    assert_includes(call, 'thing_to_do')
  end

  def test_to_language
    assert_equal(:python, Wrapture::Wrapper::CToPython.to_language)
  end

  def test_wrapped_function_call
    ns_hash = fixture_hash('namespace_with_class_and_enum')
    context = Wrapture::Context.from_namespace_hash(ns_hash)
    func = context.classes.first.functions.first
    call = Wrapture::Wrapper::CToPython.wrapped_function_call(func)

    refute_nil(call)
    assert_includes(call, 'thing_to_do')
  end

  def test_wrapper_of_overloaded_constructors
    context = Wrapture::Context.new(Wrapture::Namespace.new(%w[wrapture test]))
    class_hash = fixture_hash('class_with_overloaded_constructors')
    class_context = Wrapture::Context.from_class_hash(class_hash,
                                                      parent: context)
    context.contents << class_context
    first_constructor = class_context.constructors.first
    func = Wrapture::Wrapper::CToPython.function_wrapper(first_constructor)

    refute_nil(func)
    refute_equal('overloaded_constructor_class_init', func.name,
                 'an overloaded constructor wrapper name was not unique')
  end

  def test_wrapper_param_locals
    ns_hash = fixture_hash('cmake_c_library')
    context = Wrapture::Context.from_namespace_hash(ns_hash)
    func = context.classes.first.functions.first
    locals = Wrapture::Wrapper::CToPython.wrapper_param_locals(func)

    refute_nil(locals)
    assert_kind_of(Array, locals)
    refute_empty(locals)
    assert(locals.any? { |it| it.name == 'n1' })
    assert(locals.any? { |it| it.name == 'n2' })
  end
end
