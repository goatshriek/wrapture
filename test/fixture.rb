# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2025 Joel E. Anderson
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

# Slated for removal after migrating to symbolize_names loading.
def load_fixture(name)
  fixture_path = File.expand_path('fixtures', __dir__)
  YAML.load_file(File.join(fixture_path, "#{name}.yml"))
end

# Creates a build hash for the fixture corresponding to +name+.
def fixture_build_hash(name)
  if YAML.respond_to?('safe_load_file')
    YAML.safe_load_file(fixture_build_path(name), symbolize_names: true)
  else
    YAML.load_file(fixture_build_path(name), symbolize_names: true)
  end
end

# Creates a hash for a Wrapture spec, finding and loading the YAML file
# corresponding to +name+.
def fixture_hash(name)
  if YAML.respond_to?('safe_load_file')
    YAML.safe_load_file(fixture_yaml_path(name), symbolize_names: true)
  else
    YAML.load_file(fixture_yaml_path(name), symbolize_names: true)
  end
end

# Builds the path for a fixture's build YAML file corresponding to +name+.
def fixture_build_path(name)
  File.join(File.join(File.expand_path('fixtures', __dir__), name), 'build.yml')
end

# Builds the path for a fixture's YAML file corresponding to +name+.
def fixture_yaml_path(name)
  File.join(File.expand_path('fixtures', __dir__), "#{name}.yml")
end
