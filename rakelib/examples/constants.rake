# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2023 Joel E. Anderson
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

example_dir = File.absolute_path('docs/examples/constants')

build_root = 'build/examples/constants'
directory build_root

cpp_build_dir = "#{build_root}/cpp"
directory cpp_build_dir

python_build_dir = "#{build_root}/python"
directory python_build_dir

namespace 'examples' do
  namespace 'constants' do
    desc 'build and run constants example for C++'
    task cpp: [cpp_build_dir] do
      scope = Wrapture::Scope.load_files("#{example_dir}/vcr.yml")
      wrapper = Wrapture::CppWrapper.new(scope)
      wrapper.write_source_files(dir: cpp_build_dir)
      wrapper.write_cmake_files(dir: cpp_build_dir)
      Dir.chdir(cpp_build_dir) do
        sh "gcc #{example_dir}/vcr.c -shared -o libvcr.so -I#{example_dir}"
        include_cmd = "include_directories(\".\" \"#{example_dir}\")"
        sh "echo \"#{include_cmd}\" >> CMakeLists.txt"
        sh "cmake -DCMAKE_LIBRARY_PATH=#{example_dir} ."
        sh 'cmake --build . --target mediacenter'
        opts = "-L. -lmediacenter -lvcr -I. -I#{example_dir} -o vcr_usage_cpp"
        sh "g++ #{example_dir}/vcr_usage.cpp #{opts}"
        sh 'LD_LIBRARY_PATH=. ./vcr_usage_cpp'
      end
    end

    desc 'build and run constants example for python'
    task python: [python_build_dir] do
      scope = Wrapture::Scope.load_files("#{example_dir}/vcr.yml")
      wrapper = Wrapture::PythonWrapper.new(scope)
      wrapper.write_source_files(dir: python_build_dir)
      wrapper.write_setuptools_files(dir: python_build_dir)
      Dir.chdir(python_build_dir) do
        sh "gcc -shared -o libstove.so -I #{example_dir} #{example_dir}/stove.c"
        setup_command = 'python3 setup.py build_ext'
        sh "#{setup_command} --include-dirs #{example_dir} --build-lib ."
        envs = 'LD_LIBRARY_PATH=. PYTHONPATH=.'
        sh "#{envs} python3 #{example_dir}/stove_usage.py"
      end
    end
  end
end
