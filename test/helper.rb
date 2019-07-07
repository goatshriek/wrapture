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
  filename = "#{spec['name']}.hpp"
  class_includes = spec['includes'] || []

  includes = get_include_list filename

  class_includes.each do |class_include|
    assert_includes(includes, class_include)
  end

  validate_indentation filename
end

def validate_definition_file(spec)
  filename = "#{spec['name']}.cpp"
  class_includes = spec['includes'] || []

  includes = get_include_list filename

  class_includes.each do |class_include|
    assert_includes(includes, class_include)
  end

  validate_indentation filename
end

def validate_indentation(filename)
  line_number = 0
  indent_level = 0

  File.open(filename).each do |line|
    line_number += 1

    next if line.strip.empty?

    line.chomp!

    indent_level -= 1 if line.end_with? '}', '};'

    space_count = if line.end_with? ':'
                    (indent_level - 1) * 2
                  else
                    indent_level * 2
                  end

    fail_msg = "#{filename}: line #{line_number} should have #{space_count}" \
               ' spaces'
    assert line.start_with?(' ' * space_count), fail_msg

    indent_level += 1 if line.end_with? '{'
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
