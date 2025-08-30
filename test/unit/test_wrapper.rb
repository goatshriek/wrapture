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

require 'minitest/autorun'
require 'wrapture'

module WToX
  extend Wrapture::Wrapper
end

module WToY
  extend Wrapture::Wrapper
end

module XToZ
  extend Wrapture::Wrapper
end

module YToZ
  extend Wrapture::Wrapper
end

module ZToW
  extend Wrapture::Wrapper
end

# this is a strong directed graph
# that is, there is a path from each node to every other node
MOCK_WRAPPERS = [WToX, WToY, XToZ, YToZ, ZToW].freeze

class WrapperTest < Minitest::Test
  def test_default_paths
    default_paths = Wrapture.paths

    validate_paths(default_paths)

    Wrapture::WRAPPERS.each do |wrapper|
      assert_includes(default_paths, [wrapper],
                      'the default paths should have each wrapper by itself')
    end
  end

  def test_path_from_array_in_strong_wrapping_graph
    from = %i[x y]
    paths = Wrapture.paths(from: from, modules: MOCK_WRAPPERS)

    validate_paths(paths)

    paths.each do |path|
      assert_includes(from, path.wrappers.first.from_language,
                      "all path starts must be in #{from}")
    end

    assert_equal(MOCK_WRAPPERS.count * 2, paths.count,
                 'the number of paths for each language should equal the ' \
                 'number of wrappers')
  end

  def test_path_from_symbol_in_strong_wrapping_graph
    paths = Wrapture.paths(from: :x, modules: MOCK_WRAPPERS)

    validate_paths(paths)

    paths.each do |path|
      assert_equal(:x, path.wrappers.first.from_language,
                   'all paths must start with x')
    end

    assert_equal(MOCK_WRAPPERS.count, paths.count,
                 'the number of paths should equal the number of wrappers')
  end

  def test_strong_wrapping_graph
    paths = Wrapture.paths(modules: MOCK_WRAPPERS)

    validate_paths(paths)

    assert_equal(MOCK_WRAPPERS.count.pow(2), paths.count,
                 'the number of paths should equal the square of the number ' \
                 'of wrappers for a strong wrapping graph')
  end

  def test_path_to_array_in_strong_wrapping_graph
    to = %i[x y]
    paths = Wrapture.paths(to: to, modules: MOCK_WRAPPERS)

    validate_paths(paths)

    paths.each do |path|
      assert_includes(to, path.wrappers.last.to_language,
                      "all path ends must be in #{to}")
    end

    assert_equal(MOCK_WRAPPERS.count * 2, paths.count,
                 'the number of paths for each language should equal the ' \
                 'number of wrappers')
  end

  def test_path_to_symbol_in_strong_wrapping_graph
    paths = Wrapture.paths(to: :x, modules: MOCK_WRAPPERS)

    validate_paths(paths)

    paths.each do |path|
      assert_equal(:x, path.wrappers.last.to_language,
                   'all paths must end with x')
    end

    assert_equal(MOCK_WRAPPERS.count, paths.count,
                 'the number of paths should equal the number of wrappers')
  end

  def validate_paths(paths)
    assert_kind_of(Array, paths)
    paths.each do |path|
      assert_kind_of(Wrapture::Path, path)

      path.wrappers.each_cons(2) do |a, b|
        assert_equal(a.to_language, b.from_language,
                     'each step in a path must have the same language')
      end
    end
  end
end
