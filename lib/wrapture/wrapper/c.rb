# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025 Joel E. Anderson
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
  module Wrapper
    # Utilities for wrappers that use C as either a from or to language.
    module C
      # All includes in the given spec. For specs that include others,
      # the array will have all includes of the included items as well.
      def self.includes(spec)
        case spec
        when ClassSpec
          function_includes = spec.functions.flat_map do |it|
            includes(it)
          end
          constant_includes = spec.constants.flat_map do |it|
            includes(it)
          end
          (spec.includes + constant_includes + function_includes).uniq
        when FunctionSpec
          param_includes = spec.params.flat_map do |it|
            includes(it)
          end
          (spec.wrapped[:c].includes + param_includes).uniq
        when ConstantSpec, ParamSpec, TypeSpec
          spec.includes
        else
          []
        end
      end
    end
  end
end
