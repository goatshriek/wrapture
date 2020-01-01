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

source 'https://rubygems.org'

gemspec

gem 'json', '>= 1.8', '<= 2.2' # needed for truffleruby to work

group :development do
  gem 'rake', '>= 0.9.2'
  gem 'rdoc', '>= 6.0', '< 6.2' # 6.2 requires >= ruby 2.4.0
end

group :test do
  gem 'codecov', '>= 0.1.14', require: false
  gem 'minitest', '>= 5.9', '< 5.13' # 5.13 causes problems with rbx 4
  gem 'rubocop', '>= 0.69', require: false
  gem 'simplecov', '>= 0.16.1', require: false
end
