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
    # A C++. This may be a member function or a free function.
    class CppFunction
      include CppBlock

      # A new method is public, non-static, has no parameters, a void return,
      # and an empty body.
      def initialize(name)
        @accessibility = :public
        @name = name
        @params = []
        @return_type = Wrapture::CSource::CType.new('void')
        @static = false
        @tree = []
        @virtual = false
      end

      # The accessibility of a method can be +:public+, +:private+, or
      # +:protected+.
      attr_accessor :accessibility

      # The name of the method.
      attr_reader :name

      # The parameters of the method.
      attr_accessor :params

      # The return type of the method.
      attr_accessor :return_type

      # True if this method is static.
      attr_writer :static

      # The tree of the method body statements.
      attr_reader :tree

      # True if this method is virtual
      attr_writer :virtual

      # True if this function is static.
      def static?
        @static
      end

      # True if this function is virtual.
      def virtual?
        @virtual
      end
    end
  end
end
