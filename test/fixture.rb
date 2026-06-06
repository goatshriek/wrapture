# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2026 Joel E. Anderson
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

require 'yaml'

# A namespace that contains a basic class, constant, enum, and function.
def basic_namespace
  class_hash = fixture_hash('basic_class')
  constant_hash = fixture_hash('basic_constant')
  enum_hash = fixture_hash('basic_enum')
  func_hash = fixture_hash('basic_function')

  ns = Wrapture::PlainNamespace.new(%w[basic namespace])
  ns << Wrapture::ClassSpec.new(class_hash)
  ns << Wrapture::ConstantSpec.new(constant_hash)
  ns << Wrapture::EnumSpec.from_hash(enum_hash)
  ns << Wrapture::FunctionSpec.from_hash(func_hash)
end

# The build spec for the fixture corresponding to +name+.
def fixture_build(name)
  build = Wrapture::Build.from_hash(fixture_build_hash(name))
  build.include_dir = File.join(File.expand_path('fixtures', __dir__), name)
  build.source_dir = File.join(File.expand_path('fixtures', __dir__), name)

  build
end

# Creates a build hash for the fixture corresponding to +name+.
def fixture_build_hash(name)
  # simplify this to just safe_load_file after Ruby 2.7 is dropped
  if YAML.respond_to?('safe_load_file')
    YAML.safe_load_file(fixture_build_spec_path(name), aliases: true,
                                                       symbolize_names: true)
  else
    filename = fixture_build_spec_path(name)
    File.open(filename, 'r:bom|utf-8') do |f|
      YAML.safe_load(f, filename: filename,
                        aliases: true,
                        symbolize_names: true)
    end
  end
end

# Creates a hash for a Wrapture spec, finding and loading the YAML file
# corresponding to +name+.
def fixture_hash(name)
  # simplify this to just safe_load_file after Ruby 2.7 is dropped
  if YAML.respond_to?('safe_load_file')
    YAML.safe_load_file(fixture_yaml_path(name), aliases: true,
                                                 symbolize_names: true)
  else
    filename = fixture_yaml_path(name)
    File.open(filename, 'r:bom|utf-8') do |f|
      YAML.safe_load(f, filename: filename,
                        aliases: true,
                        symbolize_names: true)
    end
  end
end

# The path for a fixture's build output corresponding to +name+. The directory
# will be created if it does not exist.
def fixture_build_dir(name)
  dir = File.join(File.expand_path('../build/test/fixtures', __dir__), name)
  FileUtils.mkdir_p(dir)
  dir
end

# Builds the path for a fixture's build YAML file corresponding to +name+.
def fixture_build_spec_path(name)
  File.join(File.join(File.expand_path('fixtures', __dir__), name), 'build.yml')
end

# Builds the path for a fixture's YAML file corresponding to +name+.
def fixture_yaml_path(name)
  f = File.join(File.expand_path('fixtures', __dir__), "#{name}.yml")
  if File.exist?(f)
    f
  else
    File.join(File.expand_path('fixtures', __dir__), "#{name}/spec.yml")
  end
end
