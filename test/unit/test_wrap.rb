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

class WrapTest < Minitest::Test
  def test_wrap
    config = Wrapture::Config::WrapConfig.new
    scope_file = fixture_yaml_path('minimal_scope')
    scope = Wrapture::Scope.load_files(scope_file)
    config.scopes << scope
    config.paths << Wrapture::Path.new('c,cpp')

    Dir.mktmpdir do |dir|
      config.output = dir
      Wrapture.wrap(config)

      scope.classes.each do |it|
        assert_includes(Dir.children(dir), "#{it.name}.cpp")
      end
    end
  end
end