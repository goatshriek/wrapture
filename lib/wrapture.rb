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

# Classes and functions for generating language wrappers
module Wrapture
  require 'wrapture/action_spec'
  require 'wrapture/comment'
  require 'wrapture/constant_spec'
  require 'wrapture/constants'
  require 'wrapture/class_spec'
  require 'wrapture/cpp_wrapper'
  require 'wrapture/enum_spec'
  require 'wrapture/errors'
  require 'wrapture/function_spec'
  require 'wrapture/named'
  require 'wrapture/normalize'
  require 'wrapture/rule_spec'
  require 'wrapture/param_spec'
  require 'wrapture/python_wrapper'
  require 'wrapture/scope'
  require 'wrapture/struct_spec'
  require 'wrapture/template_spec'
  require 'wrapture/type_spec'
  require 'wrapture/version'
  require 'wrapture/wrapped_code_spec'
  require 'wrapture/wrapped_function_spec'
end
