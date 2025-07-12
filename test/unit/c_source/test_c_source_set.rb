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

class CSourceSetTest < Minitest::Test
  def test_c_source_set_append
    build_hash = fixture_hash('c_source_set')
    build = Wrapture::CSource::CSourceSet.from_hash(build_hash)
    added = Wrapture::CSource::CSourceSet.new('appended')
    added.add_lib_link('appended_link')
    src_file = Wrapture::SourceFile.new('appended_source.c')
    added.add_lib_source(src_file)
    header_file = Wrapture::SourceFile.new('appended_source.h')
    added.add_lib_header(header_file)
    build << added

    assert_includes(build.lib_links, 'appended_link')
    assert_includes(build.lib_sources, src_file)
    assert_includes(build.lib_headers, header_file)
  end

  def test_c_source_set_from_hash
    build_hash = fixture_hash('c_source_set')
    build = Wrapture::CSource::CSourceSet.from_hash(build_hash)

    assert_instance_of(Wrapture::CSource::CSourceSet, build)
  end
end
