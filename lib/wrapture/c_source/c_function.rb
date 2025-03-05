# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

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

module Wrapture
  module CSource
    # A C function.
    class CFunction
      include CBlock

      # The list of failure labels of the function.
      attr_reader :fail_labels

      # The name of the function.
      attr_reader :name

      # The parameters of the function.
      attr_reader :params

      # The return type of the function.
      attr_reader :return_type

      # The tree of the function body.
      attr_reader :tree

      # A new function has no parameters, void return, and an empty body.
      def initialize(name, params: [], return_type: CType.new('void'))
        @name = name
        @params = params
        @return_type = return_type
        @tree = []
        @fail_labels = []
      end

      # Add a failure label to the function, along with code that is executed
      # when this label is used. New labels are added before existing ones, so
      # that jumping to them also runs the others as well.
      def add_fail_label(name, tree)
        @fail_labels << [name, tree]
      end

      # Add a parameter to the function, in the form of a declaration of the
      # parameter as a variable. Returns the modified function.
      def add_param(decl)
        @params << decl
        self
      end
    end
  end
end
