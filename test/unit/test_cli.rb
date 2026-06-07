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
  def test_exit_on_failure
    # it would be nice if this test actually tested whether an invocation of the
    # cli had a non-zero exit on failure, but this would pull the test out of
    # a pure Ruby environment, so for now we make do with this Thor-specific
    # test
    assert_predicate(Wrapture::Cli::Command, :exit_on_failure?)
  end

  def test_help
    out, _err = capture_io do
      Wrapture::Cli::Command.start(['wrap', '--help'])
    end

    assert_match('Usage:', out)
    assert_match('Options:', out)
    assert_match('Description:', out)

    # it would be nice to test this, but older rubies have trouble with it
    # assert_empty(err)
  end

  def test_version
    out, _err = capture_io do
      Wrapture::Cli::Command.start(['wrap', '--version'])
    end

    assert_match(Wrapture::VERSION, out)

    # it would be nice to test this, but older rubies have trouble with it
    # assert_empty(err)
  end

  def test_wrap_with_from
    ns_file = fixture_yaml_path('minimal_namespace')

    Dir.mktmpdir do |dir|
      out, _err = capture_io do
        Wrapture::Cli::Command.start(['wrap',
                                      '--from',
                                      'c',
                                      '--output',
                                      dir,
                                      '--namespace',
                                      ns_file])
      end

      assert_empty(out)

      ns = Wrapture::PlainNamespace.from_yaml_file(ns_file)

      ns.classes.each do |it|
        assert_includes(Dir.children(dir), "#{it.camel_case_name}.cpp")
      end
    end
  end

  def test_wrap_with_paths
    ns_file = fixture_yaml_path('minimal_namespace')

    Dir.mktmpdir do |dir|
      out, _err = capture_io do
        Wrapture::Cli::Command.start(['wrap',
                                      '--path',
                                      'c,cpp',
                                      '--output',
                                      dir,
                                      '--namespace',
                                      ns_file])
      end

      assert_empty(out)

      ns = Wrapture::PlainNamespace.from_yaml_file(ns_file)

      ns.classes.each do |it|
        assert_includes(Dir.children(dir), "#{it.camel_case_name}.cpp")
      end
    end
  end
end
