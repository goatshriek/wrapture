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
directory 'build/examples'
CLEAN.include('build/**/*.so')
CLOBBER.include('build/**/*.c')
CLOBBER.include('build/**/*.py')

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
  directory 'build/test/python'

  desc 'Build and run Python examples'
  task examples: ['build/examples'] do
    scope = Wrapture::Scope.load_files('docs/examples/basic/stove.yml')
    Wrapture::PythonWrapper.write_spec_source_files(scope, dir: 'build/examples')
    Wrapture::PythonWrapper.write_spec_setuptools_files(scope, dir: 'build/examples')
    Dir.chdir('build/examples') do
      sh 'gcc -shared -o libstove.so -I ../../docs/examples/basic ../../docs/examples/basic/stove.c'
      sh 'python3 setup.py build_ext --include-dirs ../../docs/examples/basic --build-lib .'
      sh 'LD_LIBRARY_PATH=. PYTHONPATH=. python3 ../../docs/examples/basic/stove_usage.py'
    end
  end

  desc 'Run Python tests'
  task test: ['build/test/python'] do
    scope = Wrapture::Scope.load_files('docs/examples/basic/stove.yml')
    Wrapture::PythonWrapper.write_spec_source_files(scope, dir: 'build/test/python')
    Wrapture::PythonWrapper.write_spec_setuptools_files(scope, dir: 'build/test/python')
    Dir.chdir('build/test/python') do
      sh 'touch todo.txt'
    end
  end
end
