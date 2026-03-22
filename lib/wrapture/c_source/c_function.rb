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
  module CSource
    # A C function.
    class CFunction
      include CBlock

      # The attributes of the function.
      attr_reader :attributes

      # The action taken when an error is encountered.
      attr_accessor :error_action

      # Th rules to detect when an error has occurred.
      attr_reader :error_rules

      # The list of failure labels of the function.
      attr_reader :fail_labels

      # The includes needed to use this function.
      attr_reader :includes

      # An array of libraries required for this function call.
      attr_reader :libraries

      # The name of the function.
      attr_reader :name

      # The parameters of the function.
      attr_reader :params

      # The return type of the function.
      attr_accessor :return_type

      # The tree of the function body.
      attr_reader :tree

      # Creates a new C function from a hash.
      #
      # The only mandatory key of the hash is +:name+, which will be used as
      # the name of the created CFunction.
      #
      # The remaining keys are optional.
      #
      # The +:params+ key must be an enumerable if it exists. Each entry in this
      # enumerable must be a Hash, with a +:type+ key, and optionally +:name+
      # and/or +:value+ keys.
      #
      # The +:includes+ key must be either a single +String+ or an +Enumerable+
      # of +String+ instances, which are the includes needed to use this
      # function.
      #
      # The +:libraries+ key must be either a single +String+ or an +Enumerable+
      # of +String+ instances, which are the libraries that must be linked in
      # order to use this function.
      #
      # The +:return+ key must be a +Hash+ with a +:type+ key, which is used to
      # construct the +CType+ of the return value. It must either be a +String+
      # or a +Hash+.
      #
      # The +:error_check+ key contains a +Hash+ that has a +:rules+ and
      # +:error_action+ key which contain a +CExpression+ and +ActionSpec+ hash,
      # respectively, that describe how errors are detected and what happens
      # when they are.
      def self.from_hash(spec)
        unless spec.key?(:name)
          raise MissingSpecKey, 'a name is required for c functions'
        end

        func = CFunction.new(spec[:name])

        # TODO: factor this out into a CParam class
        if spec.key?(:params)
          spec[:params].each do |param|
            type = case param[:type]
                   when String
                     CType.from_hash({ name: param[:type] })
                   when Hash
                     CType.from_hash(param[:type])
                   else
                     CType.new(param[:type])
                   end
            name = (param[:name] if param.key?(:name))
            value = if param.key?(:value)
                      param[:value]
                    else
                      name
                    end
            func.params << CDeclaration.new(type, name, value: value)
          end
        end

        if spec.key?(:includes)
          func.includes.concat(Wrapture.normalize_array(spec[:includes]))
        end

        if spec.key?(:libraries)
          func.libraries.concat(Wrapture.normalize_array(spec[:libraries]))
        end

        if spec.key?(:return) && spec[:return].key?(:type)
          func.return_type = if spec[:return][:type].is_a?(String)
                               CType.new(spec[:return][:type])
                             else
                               CType.from_hash(spec[:return][:type])
                             end
        end

        if spec.key?(:error_check)
          check = spec[:error_check]

          check[:rules].each do |rule|
            rule_spec = { operator: rule[:condition],
                          values: [rule[:left_expression],
                                   rule[:right_expression]] }
            func.error_rules << CExpression.from_hash(rule_spec)
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
        @libraries = []
      end

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
