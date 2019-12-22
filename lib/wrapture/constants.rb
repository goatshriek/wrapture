# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2019 Joel E. Anderson
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

module Wrapture
  # A string denoting an equivalent struct type or value.
  EQUIVALENT_STRUCT_KEYWORD = 'equivalent-struct'

  # A string denoting a pointer to an equivalent struct type or value.
  EQUIVALENT_POINTER_KEYWORD = 'equivalent-struct-pointer'

  # A string denoting the return value of a wrapped function call.
  RETURN_VALUE_KEYWORD = 'return-value'

  # A list of all keywords.
  KEYWORDS = [EQUIVALENT_STRUCT_KEYWORD, EQUIVALENT_POINTER_KEYWORD,
              RETURN_VALUE_KEYWORD].freeze
end
