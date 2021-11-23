# frozen_string_literal: true

require 'bundler'
require 'rake/testtask'

Bundler::GemHelper.install_tasks

Rake::TestTask.new do |task|
  task.libs << 'test'
  task.pattern = 'test/**/test_*.rb'
end

desc 'Run tests'
task default: :test

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

desc 'Run Python tests'
task :python_test do
  require 'wrapture'

  scope = Wrapture::Scope.load_files('test/fixtures/scope_with_enum.yml')
  Wrapture::PythonWrapper.write_spec_source_files(scope)
  Wrapture::PythonWrapper.write_spec_setuptools_files(scope)
  sh 'python3 setup.py build'
  Dir.chdir('build/lib.linux-x86_64-3.6/') do
    cp '../../test/python/test_import.py', '.'
    sh 'python3 test_import.py'
  end
  rm 'setup.py'
  rm 'wrapture_test.c'
  rm_rf 'build/'
end
