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

class CToPythonIntegrationTest < Minitest::Test
  def test_cmake_c_lib_usage
    build_dir = fixture_build_dir('cmake_c_library')
    wrapped_build = fixture_build('cmake_c_library')
    wrapped_build.save_build_sources(build_dir)
    wrapped_build.build_commands.each do |cmd|
      system(cmd, chdir: build_dir, exception: true)
    end
    wrapped_build.install_commands.each do |cmd|
      system(cmd, chdir: build_dir, exception: true)
    end

    spec_hash = fixture_hash('cmake_c_library')
    scope = Wrapture::Scope.new(spec_hash)
    wrapper_sources = Wrapture::Wrapper::CToPython.wrap_scope(scope)
    wrapper_build = Wrapture::Build::PyprojectBuild.new(wrapper_sources)
    python_build_dir = File.join(build_dir, 'python')
    FileUtils.mkdir_p(python_build_dir)
    wrapper_build.save(python_build_dir)

    env = { 'CFLAGS' => "-I#{wrapped_build.include_dir} -L#{build_dir}/lib" }
    wrapper_build.build_commands.each do |cmd|
      system(env, cmd, chdir: python_build_dir, exception: true)
    end

    FileUtils.rm_rf(File.join(python_build_dir, 'usage-env'))
    venv_cmd = 'python3 -m venv usage-env'
    system(venv_cmd, chdir: python_build_dir, exception: true)

    wrapper_build.install_commands(python: 'usage-env/bin/python3').each do |cmd|
      system(cmd, chdir: python_build_dir, exception: true)
    end

    python_usage = File.join(wrapped_build.source_dir, 'python_usage.py')
    env = { 'LD_LIBRARY_PATH' => 'lib' }
    cmd = "usage-env/bin/python3 #{python_usage}"
    system(env, cmd, chdir: python_build_dir, exception: true)
  end
end
