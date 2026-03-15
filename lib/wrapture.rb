# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
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
#++

require 'wrapture/action_spec'
require 'wrapture/build'
require 'wrapture/c_source'
require 'wrapture/class_spec'
require 'wrapture/cli'
require 'wrapture/comment'
require 'wrapture/config'
require 'wrapture/constant_spec'
require 'wrapture/constants'
require 'wrapture/cpp_source'
require 'wrapture/enum_spec'
require 'wrapture/errors'
require 'wrapture/function_spec'
require 'wrapture/named'
require 'wrapture/normalize'
require 'wrapture/rule_spec'
require 'wrapture/param_spec'
require 'wrapture/path'
require 'wrapture/python_source'
require 'wrapture/scope'
require 'wrapture/source_file'
require 'wrapture/source_set'
require 'wrapture/struct_spec'
require 'wrapture/template_spec'
require 'wrapture/type_spec'
require 'wrapture/version'
require 'wrapture/wrap'
require 'wrapture/wrapper'

# Classes and functions for generating language wrappers.
module Wrapture
end
