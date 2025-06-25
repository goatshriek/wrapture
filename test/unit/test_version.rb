# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2020-2025 Joel E. Anderson
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

class VersionTest < Minitest::Test
  def test_gemspec_date
    spec = Gem::Specification.load('wrapture.gemspec')

    date_regex = /^## \[(\d+\.\d+\.\d+)\] - (\d{4}-\d{2}-\d{2})/
    File.open('ChangeLog.md').each do |line|
      date_regex.match(line) do |match_data|
        if match_data[1] == spec.version.to_s
          assert_equal(match_data[2], spec.date.strftime('%Y-%m-%d'),
                       'the changelog date and gem date do not match')
        end
      end
    end
  end

  def test_gemspec_version
    spec = Gem::Specification.load('wrapture.gemspec')
    spec_version = spec.version.to_s

    assert_equal Wrapture::VERSION, spec_version
  end

  def test_version_syntax
    assert_match(/\d+\.\d+\.\d+/, Wrapture::VERSION)
  end
end
