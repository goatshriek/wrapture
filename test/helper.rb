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

def get_include_list(filename)
  includes = []
  File.open(filename).each do |line|
    if (m = line.match(/#\s*include\s*["<](.*)[">]/))
      includes << m[1]
    end
  end

  includes
end

def validate_declaration_file(spec)
  class_includes = spec['includes'] || []

  includes = get_include_list "#{spec['name']}.hpp"

  class_includes.each do |class_include|
    assert_includes(includes, class_include)
  end
end

def validate_definition_file(spec)
  class_includes = spec['includes'] || []

  includes = get_include_list "#{spec['name']}.cpp"

  class_includes.each do |class_include|
    assert_includes(includes, class_include)
  end
end

def validate_wrapper_results(spec, file_list)
  refute_nil file_list
  refute_empty file_list
  assert file_list.length == 2
  assert file_list.include? "#{spec['name']}.cpp"
  assert file_list.include? "#{spec['name']}.hpp"

  validate_declaration_file(spec)
  validate_definition_file(spec)
end
