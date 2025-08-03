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
  module CSource
    # A C function.
    class CFunction
      include CBlock

      # Creates a new C function from a hash.
      def self.from_hash(spec)
        unless spec.key?(:name)
          raise MissingSpecKey, 'a name is required for c functions'
        end

        func = CFunction.new(spec[:name])

        if spec.key?(:includes)
          func.includes = Wrapture.normalize_array(spec[:includes])
        end

        if spec.key?(:error_check)
          check = @spec[:error_check]

          func.error_rules = check[:rules].map do |rule_spec|
            RuleSpec.new(rule_spec)
          end

          unless func.error_rules.empty?
            func.error_action = ActionSpec.new(check[:error_action])
          end
        end

        func
      end

      # A new function has no parameters, void return, and an empty body.
      #
      # An enumerable of CDeclaration objects can be provided in +params+, which
      # will be used as the function parameters.
      def initialize(name, params: [], return_type: CType.new('void'),
                     attributes: [])
        @attributes = attributes
        @includes = []
        @name = name
        @params = params
        @return_type = return_type
        @tree = []
        @fail_labels = []
        @error_action = nil
        @error_rules = []
      end

      # The attributes of the function.
      attr_reader :attributes

      # The action taken when an error is encountered.
      attr_accessor :error_action

      # Th rules to detect when an error has occurred.
      attr_accessor :error_rules

      # The list of failure labels of the function.
      attr_reader :fail_labels

      # The includes needed to use this function.
      attr_accessor :includes

      # The name of the function.
      attr_reader :name

      # The parameters of the function.
      attr_reader :params

      # The return type of the function.
      attr_reader :return_type

      # The tree of the function body.
      attr_reader :tree

      # Add a failure label to the function, along with code that is executed
      # when this label is used. New labels are added before existing ones, so
      # that jumping to them also runs the others as well.
      def add_fail_label(name, tree = '')
        @fail_labels << [name, tree]
      end

      # Add a parameter to the function, in the form of a declaration of the
      # parameter as a variable. Returns the modified function.
      def add_param(decl)
        @params << decl
        self
      end

      # A declaration of this function.
      def declaration
        Wrapture::CSource::CDeclaration.new(self, @name)
      end

      # True if the wrapped function has an error check associated with it.
      def error_check?
        !@error_rules.empty?
      end
    end
  end
end
