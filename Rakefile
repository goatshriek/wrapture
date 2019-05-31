# frozen_string_literal: true

require 'bundler'
require 'rake/testtask'
require 'rdoc/task'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |task|
  task.libs << 'test'
end

desc 'Run tests'
task default: :test

RDoc::Task.new do |rdoc|
  rdoc.rdoc_files = ['lib']
  rdoc.rdoc_dir = 'docs/html'
end
