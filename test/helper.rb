# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2020 Joel E. Anderson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

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
require 'wrapture'

def all_spec_includes(spec)
  return [] unless spec.is_a?(Hash) || spec.is_a?(Array)

  includes = []

  if spec.is_a?(Array)
    spec.each do |item|
      includes.concat(all_spec_includes(item))
    end

    return includes
  end

  spec.each_pair do |key, value|
    if key == 'includes'
      if value.is_a?(Array)
        includes.concat(value)
      else
        includes << value
      end
    end

    includes.concat(all_spec_includes(value))
  end

  includes
end

def block_collector
  lines = []
  proc { |line| lines << line }
end

def count_matches(filename, regex)
  count = 0

  File.open(filename).each do |line|
    count += 1 if line.match(regex)
  end

  count
end

def file_contains_match(filename, regex)
  File.open(filename).each do |line|
    return true if line.match(regex)
  end

  false
end

def get_include_list(filename)
  includes = []
  File.open(filename).each do |line|
    if (m = line.match(/#\s*include\s*["<](.*)[">]/))
      includes << m[1]
    end
  end

  includes
end

def validate_class_wrapper(spec, file_list)
  refute_nil(file_list)
  refute_empty(file_list)

  assert(file_list.include?("#{spec['name']}.cpp"))
  assert(file_list.include?("#{spec['name']}.hpp"))

  validate_declaration_file(spec)
  validate_definition_file(spec)
end

def validate_declaration_file(spec)
  filename = "#{spec['name']}.hpp"
  class_includes = Wrapture::ClassSpec.normalize_spec_hash(spec)['includes']

  includes = get_include_list filename

  class_includes.each do |class_include|
    assert_includes(includes, class_include)
  end

  validate_indentation filename
  validate_members(spec, filename)
  validate_namespace(spec, filename)
end

def validate_definition_file(spec)
  filename = "#{spec['name']}.cpp"
  normalized = Wrapture::ClassSpec.normalize_spec_hash(spec)
  class_includes = normalized['includes']

  includes = get_include_list filename

  class_includes.each do |class_include|
    assert_includes(includes, class_include)
  end

  sig = "#{spec['name']}::#{spec['name']}\\( struct \\w+ \\*equivalent \\)"
  def_count = count_matches(filename, sig)
  assert(def_count <= 1)

  normalized['functions'].each do |func_spec|
    sig = "#{spec['name']}::#{func_spec['name']}\\("
    def_count = count_matches(filename, sig)
    assert_equal(1, def_count, "not one definition of #{func_spec['name']}")
  end

  validate_indentation filename
  validate_namespace(spec, filename)
end

def validate_indentation(filename)
  line_number = 0
  indent_level = 0

  File.open(filename).each do |line|
    line_number += 1

    next if line.strip.empty?

    line.chomp!

    indent_level -= 1 if line.end_with?('}', '};') ||
                         line.include?('} if') ||
                         line.include?('} else')

    msg_prefix = "#{filename}: line #{line_number}"
    validate_space_count(line, indent_level, msg_prefix)

    indent_level += 1 if line.end_with?('{')
  end
end

def validate_members(spec, filename)
  return unless spec.key?('equivalent-struct')

  equiv_struct = spec['equivalent-struct']
  return unless equiv_struct['members']

  first_member_name = equiv_struct['members'][0]['name']

  fail_msg = 'no constructor for struct members generated'
  assert file_contains_match(filename, first_member_name), fail_msg
end

def validate_namespace(spec, filename)
  assert file_contains_match(filename, /namespace \w+/), 'namespace was invalid'
  assert file_contains_match(filename, "namespace #{spec['namespace']}")
end

def validate_space_count(line, indent_level, msg_prefix)
  space_count = if line.end_with?(':')
                  (indent_level - 1) * 2
                else
                  indent_level * 2
                end

  fail_msg = "#{msg_prefix} should have #{space_count} spaces"
  assert(line.start_with?(' ' * space_count), fail_msg)
end

def validate_wrapper_results(spec, file_list)
  if spec.key?('classes')
    spec['classes'].each do |class_spec|
      validate_class_wrapper(class_spec, file_list)
    end
  else
    assert(file_list.length == 2, msg: 'only 2 files expected per class')
    validate_class_wrapper(spec, file_list)
  end
end
