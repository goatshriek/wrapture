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

namespace 'python' do
  desc 'Run Python tests'
  task :test do
    require 'wrapture'

    scope = Wrapture::Scope.load_files('test/fixtures/scope_with_enum.yml')
    Wrapture::PythonWrapper.write_spec_source_files(scope)
    Wrapture::PythonWrapper.write_spec_setuptools_files(scope)
    sh 'python3 setup.py build --build-lib .'
    cp 'test/python/test_import.py', '.'
    sh 'python3 test_import.py'
    rm 'setup.py'
    rm Dir.glob('wrapture_test.*')
    rm 'test_import.py'
    rm_rf 'build/'
  end
end
