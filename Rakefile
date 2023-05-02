# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2021-2023 Joel E. Anderson
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

require 'bundler'
require 'rake/clean'
require 'rake/testtask'
require 'wrapture'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |task|
  task.libs << 'test'
  task.pattern = 'test/**/test_*.rb'
end

desc 'Run tests'
task default: :test

# build directory to hold intermediate and generated files
build_dir = 'build' # this should be made configurable later
build_examples_dir = "#{build_dir}/examples"
directory build_examples_dir
CLEAN.include("#{build_dir}/**/*.so")
CLOBBER.include("#{build_dir}/**/*.c")
CLOBBER.include("#{build_dir}/**/*.py")

begin
  require 'rdoc/task'

  RDoc::Task.new do |rdoc|
    rdoc.rdoc_files = ['lib', 'README.md']
    rdoc.rdoc_dir = 'docs/html'
    rdoc.main = 'README.md'
  end
rescue LoadError
  puts 'could not load rdoc/task module'
end

namespace 'python' do
  desc 'Build and run Python examples'
  task examples: [build_examples_dir] do
    example_dir = File.absolute_path('docs/examples/basic')
    scope = Wrapture::Scope.load_files("#{example_dir}/stove.yml")
    wrapper = Wrapture::PythonWrapper.new(scope)
    wrapper.write_source_files(dir: build_examples_dir)
    wrapper.write_setuptools_files(dir: build_examples_dir)
    Dir.chdir(build_examples_dir) do
      sh "gcc -shared -o libstove.so -I #{example_dir} #{example_dir}/stove.c"
      setup_command = 'python3 setup.py build_ext'
      sh "#{setup_command} --include-dirs #{example_dir} --build-lib ."
      sh "LD_LIBRARY_PATH=. PYTHONPATH=. python3 #{example_dir}/stove_usage.py"
    end
  end

  build_test_dir = "#{build_dir}/test/python"
  directory build_test_dir

  desc 'Run Python tests'
  task test: ['build/test/python'] do
    Dir.chdir(build_test_dir) do
      sh 'touch todo.txt'
    end
  end
end
