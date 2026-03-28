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

class CToCppIntegrationTest < Minitest::Test
  def test_cmake_c_lib_usage
    # build and install the c library that is being wrapped
    build_dir = fixture_build_dir('cmake_c_library')
    wrapped_build = fixture_build('cmake_c_library')
    wrapped_build.save_build_sources(build_dir)
    wrapped_build.build_commands.each do |cmd|
      system(cmd, chdir: build_dir, exception: true)
    end
    wrapped_build.install_commands.each do |cmd|
      system(cmd, chdir: build_dir, exception: true)
    end

    # create the c++ wrapper and a CMake build
    spec_hash = fixture_hash('cmake_c_library')
    scope = Wrapture::Scope.from_hash(spec_hash)
    wrapper_sources = Wrapture::Wrapper::CToCpp.wrap_scope(scope)
    wrapper_build = Wrapture::Build::CmakeBuild.new(wrapper_sources)

    # write the wrapper source files
    cpp_build_dir = File.join(build_dir, 'cpp')
    FileUtils.mkdir_p(cpp_build_dir)
    wrapper_build.save(cpp_build_dir)

    # build the wrapper
    env = { 'CMAKE_LIBRARY_PATH' => "#{build_dir}/lib",
            'CXXFLAGS' => "-I#{build_dir}/include" }
    wrapper_build.build_commands.each do |cmd|
      system(env, cmd, chdir: cpp_build_dir, exception: true)
    end

    # install the wrapper
    wrapper_build.install_commands(install_dir: build_dir).each do |cmd|
      system(cmd, chdir: cpp_build_dir, exception: true)
    end

    # build and run the c++ usage program
    cpp_usage = File.join(wrapped_build.source_dir, 'cpp_usage.cpp')
    wrapper_link = wrapper_build.source_set.name
    wrapped_link = wrapped_build.source_set.name
    links = "-l#{wrapper_link} -l#{wrapped_link}"
    build_cmd = "g++ -L lib -I include #{cpp_usage} #{links} -o cpp_usage"
    build_success = system(build_cmd, chdir: build_dir, exception: true)

    assert(build_success)
    usage_success = system('./cpp_usage', chdir: build_dir, exception: true)

    assert(usage_success)
  end
end
