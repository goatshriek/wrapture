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

class CliTest < Minitest::Test
  def test_help
    out, err = capture_io do
      Wrapture::Cli::Command.start(['wrap', '--help'])
    end

    assert_match('Usage:', out)
    assert_match('Options:', out)
    assert_match('Description:', out)

    # it would be nice to test this, but older rubies have trouble with it
    # assert_empty(err)
  end

  def test_version
    out, err = capture_io do
      Wrapture::Cli::Command.start(['wrap', '--version'])
    end

    assert_match(Wrapture::VERSION, out)

    # it would be nice to test this, but older rubies have trouble with it
    # assert_empty(err)
  end
end
