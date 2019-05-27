# frozen_string_literal: true

require 'minitest/autorun'

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

def validate_wrapper_results(spec, file_list)
  refute_nil file_list
  refute_empty file_list
  assert file_list.length == 2
  assert file_list.include? "#{spec['name']}.cpp"
  assert file_list.include? "#{spec['name']}.hpp"
end
