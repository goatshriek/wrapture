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
      # Class constants.
      attr_reader :constants

      # The constructors of this class.
      attr_reader :constructors

      # The data members of the class.
      attr_accessor :data_members

      # The destructor for the class, if a non-default one is needed.
      attr_accessor :destructor

      # The documentation for the class.
      attr_accessor :doc

      # The equivalent member declaration for the class. This is a duplicate of
      # the declaration in +data_members+, to be used when needed for things
      # like casting.
      attr_accessor :equivalent_member

      # The methods of this class.
      attr_reader :member_functions

      # The name of the class.
      attr_reader :name

      # The fully qualified name of the parent class.
      attr_accessor :parent_name

      # A C++ class must have a name, at a minimum.
      def initialize(name)
        @constants = []
        @constructors = []
        @data_members = []
        @destructor = nil
        @doc = Comment.new
        @equivalent_member = nil
        @member_functions = []
        @name = name
        @parent_name = nil
      end
    end
  end
end
