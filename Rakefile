# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2021-2025 Joel E. Anderson
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

# build directory to hold intermediate and generated files
build_dir = 'build' # this should be made configurable later
CLEAN.include("#{build_dir}/**/*.so")
CLOBBER.include("#{build_dir}/**/*.c")
CLOBBER.include("#{build_dir}/**/*.py")

Bundler::GemHelper.install_tasks

namespace 'test' do
  Rake::TestTask.new(:unit) do |task|
    task.description = 'Run unit tests'
    task.libs << 'test'
    task.pattern = 'test/unit/**/test_*.rb'
  end

  namespace 'integration' do
    Rake::TestTask.new(:c_to_cpp) do |task|
      task.description = 'Run C to C++ integration tests'
      task.libs << 'test'
      task.pattern = 'test/integration/test_c_to_cpp*.rb'
    end

    Rake::TestTask.new(:c_to_python) do |task|
      task.description = 'Run C to Python integration tests'
      task.libs << 'test'
      task.pattern = 'test/integration/test_c_to_python*.rb'
    end
  end

  desc 'Run all integration tests'
  task integration: ['test:integration:c_to_cpp',
                     'test:integration:c_to_python']
end

desc 'Run all tests'
task test: ['test:integration', 'test:unit']

desc 'Run unit tests (test:unit)'
task default: 'test:unit'

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
    next unless task.name =~ task_regex

    task.reenable
    task.invoke
  end
end

namespace 'examples' do
  desc 'Build and run all examples wrapping C with C++'
  task :c_to_cpp do
    run_matching_tasks(lang_examples_regex('cpp'))
  end

  desc 'Build and run all examples wrapping C with Python'
  task :c_to_python do
    run_matching_tasks(lang_examples_regex('python'))
  end
end
