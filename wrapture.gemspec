# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019-2021 Joel E. Anderson
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

Gem::Specification.new do |spec|
  spec.name        =  'wrapture'
  spec.version     =  '0.6.0'
  spec.date        =  '2021-02-10'
  spec.summary     =  'wrap C in C++'
  spec.description =  'Wraps C code in C++.'
  spec.authors     =  ['Joel Anderson']
  spec.email       =  'joelanderson333@gmail.com'
  spec.files       =  Dir.glob('{lib,bin}/**/*').reject do |file_or_dir|
    File.directory?(file_or_dir)
  end
  spec.executables << 'wrapture'
  spec.homepage    =  'https://goatshriek.github.io/wrapture/'
  spec.license     =  'Apache-2.0'

  spec.required_ruby_version = '>= 2.4'
  spec.add_runtime_dependency 'json', '~> 2.3'
  spec.add_development_dependency 'bundler', '>= 1.6.4', '< 2.3'
  spec.add_development_dependency 'rake', '>= 0.9.2'
  spec.add_development_dependency 'rdoc', '>= 6.0'

  if spec.respond_to?(:metadata)
    spec.metadata = {
      'bug_tracker_uri' => 'https://github.com/goatshriek/wrapture/issues',
      'changelog_uri' => 'https://github.com/goatshriek/wrapture/blob/latest/ChangeLog.md',
      'documentation_uri' => 'https://goatshriek.github.io/wrapture/rdoc/',
      'source_code_uri' => 'https://github.com/goatshriek/wrapture/'
    }
  end
end
