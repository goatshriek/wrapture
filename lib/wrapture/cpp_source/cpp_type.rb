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
      # Get a C++ type that corresponds to a given TypeSpec.
      def self.from_spec(type_spec)
        if type_spec.pointer?
          CSource::CPointer.new(type_spec.base)
        else
          new(type_spec.name)
        end
      end

      # A C++ type is defined as a name.
      def initialize(name)
        @name = name
      end

      # The name of the type.
      attr_accessor :name
    end
  end
end
