# frozen_string_literal: true

begin
  require 'simplecov'
  SimpleCov.start do
    add_filter '/test/'
  end

  if ENV['CI']
    require 'codecov'
    SimpleCov.formatter = SimpleCov::Formatter::Codecov
  end
rescue LoadError
  puts 'could not load code coverage tools'
end

require 'minitest/autorun'

def validate_wrapper_results(spec, file_list)
  refute_nil file_list
  refute_empty file_list
  assert file_list.length == 2
  assert file_list.include? "#{spec['name']}.cpp"
  assert file_list.include? "#{spec['name']}.hpp"

  class_includes = spec['includes'] || []

  header_includes = []
  File.open("#{spec['name']}.hpp").each do |line|
    if(m=line.match(/#\s*include\s*["<](.*)[">]/))
      header_includes << m[1]
    end
  end

  class_includes.each do |class_include|
    assert_includes(header_includes, class_include)
  end

  source_includes = []
  File.open("#{spec['name']}.hpp").each do |line|
    if(m=line.match(/#\s*include\s*["<](.*)[">]/))
      source_includes << m[1]
    end
  end

  class_includes.each do |class_include|
    assert_includes(source_includes, class_include)
  end
end
