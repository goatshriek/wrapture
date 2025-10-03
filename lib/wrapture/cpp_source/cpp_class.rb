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
  module CppSource
    # A class used in C++ code.
    class CppClass
      # A C++ class has methods and attributes.
      def initialize(name)
        @name = name
        @parent_name = nil
        @public_methods = []
      end

      # The name of the class.
      attr_reader :name

      # The fully qualified name of the parent class.
      attr_accessor :parent_name

      # The member functions for this class with public access.
      attr_accessor :public_methods
    end
  end
end
