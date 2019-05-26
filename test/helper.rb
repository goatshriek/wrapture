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
