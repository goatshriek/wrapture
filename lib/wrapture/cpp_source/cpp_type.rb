# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025-2026 Joel E. Anderson
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
  module CppSource
    # A type used in C++ code.
    class CppType
      # The name of the type.
      attr_reader :name

      # Get a C++ type that corresponds to a given TypeSpec.
      def self.from_type_spec(type_spec, context: nil)
        return new('void') if type_spec.void?

        if type_spec.self?
          if context.nil?
            msg = "cannot define a CppType of 'self' " \
                  'without a context to resolve it'
            raise UndefinableSpec, msg
          end

          class_spec = context.parent_class
          if class_spec.nil?
            msg = "cannot define a CppType of 'self' with no parent class to " \
                  'resolve it'
            raise UndefinableSpec, msg
          end

          return new(class_spec.upper_camel_case_name)
        end

        return new('int') if type_spec.int?
        return new('const char *') if type_spec.string?

        new(type_spec.upper_camel_case_name)
      end

      # A C++ type is defined as a name.
      def initialize(name)
        @name = name
      end
    end
  end
end
