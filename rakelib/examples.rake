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

def run_cpp_example(name, lib, source, build_dir)
  example_dir = File.absolute_path("docs/examples/#{name}")

  scope = Wrapture::Scope.load_files("#{example_dir}/#{lib}.yml")
  wrapper = Wrapture::CppWrapper.new(scope)
  wrapper.write_source_files(dir: build_dir)
  wrapper.write_cmake_files(dir: build_dir)

  Dir.chdir(build_dir) do
    opts = "-I. -I#{example_dir} -o #{lib}_usage_cpp"

    if source
      sh "gcc #{example_dir}/#{source} -shared -o lib#{lib}.so -I#{example_dir}"
      opts += " -L. -l#{scope.name} -l#{lib}"

      include_cmd = "include_directories(\".\" \"#{example_dir}\")"
      sh "echo \"#{include_cmd}\" >> CMakeLists.txt"
      sh "cmake -DCMAKE_LIBRARY_PATH=#{example_dir} ."
      sh "cmake --build . --target #{scope.name}"
    end

    sh "g++ #{example_dir}/#{lib}_usage.cpp #{opts}"
    sh "LD_LIBRARY_PATH=. ./#{lib}_usage_cpp"
  end
end

def run_python_example(name, lib, source, build_dir)
  example_dir = File.absolute_path("docs/examples/#{name}")

  scope = Wrapture::Scope.load_files("#{example_dir}/#{lib}.yml")
  wrapper = Wrapture::PythonWrapper.new(scope)
  wrapper.write_source_files(dir: build_dir)
  wrapper.write_setuptools_files(dir: build_dir)

  Dir.chdir(build_dir) do
    if source
      sh "gcc #{example_dir}/#{source} -shared -o lib#{lib}.so -I#{example_dir}"
    end
    setup_command = 'python3 setup.py build_ext'
    sh "#{setup_command} --include-dirs #{example_dir} --build-lib ."
    envs = 'LD_LIBRARY_PATH=. PYTHONPATH=.'
    sh "#{envs} python3 #{example_dir}/#{lib}_usage.py"
  end
end

example_list = [{ name: 'basic', lib: 'stove', source: 'stove.c' },
                { name: 'constants', lib: 'vcr', source: 'vcr.c' },
                { name: 'enumerations', lib: 'fruit', source: nil }]

namespace 'examples' do
  example_list.each do |ex|
    namespace ex[:name] do
      build_root = "build/examples/#{ex[:name]}"
      directory build_root

      cpp_build_dir = "#{build_root}/cpp"
      directory cpp_build_dir

      desc 'build and run basic example for C++'
      task cpp: [cpp_build_dir] do
        run_cpp_example(ex[:name], ex[:lib], ex[:source], cpp_build_dir)
      end

      python_build_dir = "#{build_root}/python"
      directory python_build_dir

      desc 'build and run basic example for python'
      task python: [python_build_dir] do
        run_python_example(ex[:name], ex[:lib], ex[:source], python_build_dir)
      end
    end
  end
end
