# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2024 Joel E. Anderson
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

module Wrapture
  # Generic wrapping functionality.
  #
  # This module expects the following functions to be implemented:
  # +self.wrap_class+
  # +self.wrap_enum+
  # +self.wrap_scope+
  module Wrapper
    # Generates a wrapper for a given spec.
    def wrap(spec)
      case spec
      when ClassSpec
        wrap_class(spec)
      when EnumSpec
        wrap_enum(spec)
      when Scope
        wrap_scope(spec)
      end
    end
  end
end
