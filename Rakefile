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

Rake.add_rakelib 'rakelib/examples'

# Returns a regex for matching all example tasks for a given language.
def lang_examples_regex(lang)
  Regexp.new("^examples:[^:]+:#{lang}$")
end

# Runs all tasks with names matching the given regex.
def run_matching_tasks(task_regex)
  Rake.application.tasks.each do |task|
    next if task.name =~ task_regex

    task.reenable
    task.invoke
  end
end

namespace 'examples' do
  desc 'build and run all examples with C++'
  task :cpp do
    run_matching_tasks(lang_examples_regex('cpp'))
  end

  desc 'build and run all examples with Python'
  task :python do
    run_matching_tasks(lang_examples_regex('python'))
  end
end

namespace 'python' do
  build_test_dir = "#{build_dir}/test/python"
  directory build_test_dir

  desc 'run Python tests'
  task test: ['build/test/python'] do
    Dir.chdir(build_test_dir) do
      sh 'touch todo.txt'
    end
  end
end
