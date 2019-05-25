# frozen_string_literal: true

begin
  require 'simplecov'
  SimpleCov.start

  require 'codecov'
  SimpleCov.formatter = SimpleCov::Formatter::Codecov
rescue LoadError
  puts 'could not load code coverage tools'
end
