# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2023-2026 Joel E. Anderson
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

def run_cpp_example(name, lib, sources, build_dir)
  example_dir = File.absolute_path("docs/examples/#{name}")

  scope = Wrapture::Scope.load_files("#{example_dir}/#{lib}.yml")
  build = Wrapture::Wrapper::CToCpp.wrap_scope(scope)
  Wrapture::Build::CmakeBuild.new(build).save(build_dir)

  Dir.chdir(build_dir) do
    usage_opts = "-Iinclude -I#{example_dir} -o #{lib}_usage_cpp"

    if sources
      source_opts = "-shared -o lib#{lib}.so -fPIC -I#{example_dir}"
      source_files = sources.map { |s| "#{example_dir}/#{s}" }.join(' ')
      sh "gcc #{source_files} #{source_opts}"
      usage_opts += " -L. -l#{scope.name} -l#{lib}"

      include_cmd = "include_directories(\".\" \"#{example_dir}\")"
      sh "echo \"#{include_cmd}\" >> CMakeLists.txt"
      sh 'cmake -DCMAKE_LIBRARY_PATH=. .'
      sh "cmake --build . --target #{scope.name}"
    end

    sh "g++ #{example_dir}/#{lib}_usage.cpp #{usage_opts}"
    sh "LD_LIBRARY_PATH=. ./#{lib}_usage_cpp"
  end
end

def run_python_example(name, lib, sources, build_dir)
  example_dir = File.absolute_path("docs/examples/#{name}")
  load_dir = File.absolute_path(build_dir)

  scope = Wrapture::Scope.load_files("#{example_dir}/#{lib}.yml")
  build = Wrapture::Wrapper::CToPython.wrap_scope(scope)
  python_build = Wrapture::Build::PyprojectBuild.new(build)

  Dir.chdir(build_dir) do
    # build the shared library if needed
    if sources
      source_opts = "-shared -o lib#{lib}.so -fPIC -I#{example_dir}"
      source_files = sources.map { |s| "#{example_dir}/#{s}" }.join(' ')
      sh "gcc #{source_files} #{source_opts}"
    end

    # generate, build, and install the python example
    python_build.save
    cflags = "-I#{example_dir} -L#{load_dir}"
    python_build.build_commands.each do |cmd|
      # TODO: using --wheel directly on each cmd is brittle
      sh "CFLAGS=\"#{cflags}\" #{cmd} --wheel"
    end

    sh 'python3 -m venv usage-env'

    # TODO: add uninstall commands and run them to clean things up

    python_build.install_commands(python: 'usage-env/bin/python3').each do |cmd|
      sh cmd
    end
    envs = 'LD_LIBRARY_PATH=.'
    sh "#{envs} usage-env/bin/python3 #{example_dir}/#{lib}_usage.py"
  end
end

examples = [{ name: 'basic', lib: 'stove', sources: ['stove.c'] },
            { name: 'constants', lib: 'vcr', sources: ['vcr.c'] },
            { name: 'enumerations', lib: 'fruit', sources: nil },
            { name: 'exceptions', lib: 'turret',
              sources: ['turret.c', 'turret_error.c'] },
            { name: 'inheritance', lib: 'mylib', sources: ['mylib.c'] },
            { name: 'nested_structs', lib: 'fridge', sources: ['fridge.c'] },
            { name: 'overloaded_struct',
              lib: 'security_system',
              sources: ['security_system.c'] },
            { name: 'struct_wrapper', lib: 'stats', sources: ['stats.c'] }]

namespace 'examples' do
  examples.each do |ex|
    namespace ex[:name] do
      build_root = "build/examples/#{ex[:name]}"
      directory build_root

      cpp_build_dir = "#{build_root}/cpp"
      directory cpp_build_dir

      desc 'build and run basic example for C++'
      task cpp: [cpp_build_dir] do
        run_cpp_example(ex[:name], ex[:lib], ex[:sources], cpp_build_dir)
      end

      python_build_dir = "#{build_root}/python"
      directory python_build_dir

      desc 'build and run basic example for python'
      task python: [python_build_dir] do
        run_python_example(ex[:name], ex[:lib], ex[:sources], python_build_dir)
      end
    end
  end
end
