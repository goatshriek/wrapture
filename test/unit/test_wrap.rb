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

class WrapTest < Minitest::Test
  def test_wrap
    config = Wrapture::Config::WrapConfig.new
    ns_file = fixture_yaml_path('minimal_namespace')
    ns = Wrapture::PlainNamespace.from_yaml_file(ns_file)
    config.namespaces << ns
    config.paths << Wrapture::Path.new('c,cpp')

    Dir.mktmpdir do |dir|
      config.output = dir
      Wrapture.wrap(config)

      ns.classes.each do |it|
        assert_includes(Dir.children(dir), "#{it.upper_camel_case_name}.cpp")
      end
    end
  end
end
