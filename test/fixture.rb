# frozen_string_literal: true

require 'yaml'

def load_fixture(name)
  fixture_path = File.expand_path('fixtures', __dir__)
  YAML.load_file(File.join(fixture_path, "#{name}.yml"))
end
