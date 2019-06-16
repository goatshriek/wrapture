# frozen_string_literal: true

require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |task|
  task.libs << 'test'
end

desc 'Run tests'
task default: :test

begin
  require 'rdoc/task'

  RDoc::Task.new do |rdoc|
    rdoc.rdoc_files = ['lib']
    rdoc.rdoc_dir = 'docs/html'
  end
rescue LoadError
  puts 'could not load rdoc module'
end
