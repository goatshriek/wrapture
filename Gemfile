# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

gem 'json', '>= 1.8', '<= 2.2' # needed for truffleruby to work

group :development do
  gem 'rake', '>= 0.9.2'
  gem 'rdoc', '~> 6.0'
end

group :test do
  gem 'codecov', '>= 0.1.14', require: false
  gem 'minitest', '>= 5.9'
  gem 'rubocop', '>= 0.69', require: false
  gem 'simplecov', '>= 0.16.1', require: false
end
