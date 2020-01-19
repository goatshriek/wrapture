# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

# Copyright 2020 Joel E. Anderson
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
  # A template spec that can be referenced in other specs.
  class TemplateSpec
    # True if the provided spec is a template parameter with the given name.
    def self.param?(spec, param_name)
      spec.is_a?(Hash) &&
        spec.key?('is-param') &&
        spec['is-param'] &&
        spec['name'] == param_name
    end

    # Gives a spec with all instances of a parameter with the given name
    # replaced with the given value in the provided spec.
    def self.replace_param(spec, param_name, param_value)
      replace_param!(spec.dup, param_name, param_value)
    end

    # Replaces all instances of a parameter with the given name with the given
    # value in the provided spec.
    def self.replace_param!(spec, param_name, param_value)
      if spec.is_a?(Hash)
        replace_param_in_hash(spec, param_name, param_value)
      elsif spec.is_a?(Array)
        replace_param_in_array(spec, param_name, param_value)
      end
    end

    # Replaces all instances of a parameter with the given name with the given
    # value in the provided spec, assuming the spec is an array.
    def self.replace_param_in_array(spec, param_name, param_value)
      spec.map! do |value|
        if param?(value, param_name)
          param_value
        else
          replace_param!(value, param_name, param_value)
          value
        end
      end
    end
    private_class_method :replace_param_in_array

    # Replaces all instances of a parameter with the given name with the given
    # value in the provided spec, assuming the spec is a hash.
    def self.replace_param_in_hash(spec, param_name, param_value)
      spec.each_pair do |key, value|
        if param?(value, param_name)
          spec[key] = param_value
        else
          replace_param!(value, param_name, param_value)
        end
      end
    end
    private_class_method :replace_param_in_hash

    # Creates a new template with the given hash spec.
    def initialize(spec)
      @spec = spec
    end

    # Returns a spec hash of this template with the provided parameters
    # substituted.
    def instantiate(params = nil)
      result_spec = Marshal.load(Marshal.dump(@spec['value']))

      return result_spec if params.nil?

      params.each do |param|
        TemplateSpec.replace_param!(result_spec, param['name'], param['value'])
      end

      result_spec
    end

    # The name of the template.
    def name
      @spec['name']
    end

    # Replaces all references to this template with an instantiation of it in
    # the given spec.
    def replace_uses(spec)
      if spec.is_a?(Hash)
        replace_uses_in_hash(spec)
      elsif spec.is_a?(Array)
        replace_uses_in_array(spec)
      else
        spec
      end
    end

    # True if the given spec is a reference to this template.
    def use?(spec)
      spec.is_a?(Hash) &&
        spec.key?('use-template') &&
        spec['use-template']['name'] == name
    end

    private

    # Replaces all references to this template with an instantiation of it in
    # the given spec, assuming it is a hash.
    def replace_uses_in_hash(spec)
      if use?(spec)
        spec.merge!(instantiate(spec['use-template']['params']))
        spec.delete('use-template')
      end

      spec.each_value do |value|
        replace_uses(value)
      end

      spec
    end

    # Replaces all references to this template with an instantiation of it in
    # the given spec, assuming it is an array.
    def replace_uses_in_array(spec)
      spec.dup.each_index do |i|
        if use?(spec[i])
          result = instantiate(spec[i]['use-template']['params'])
          if result.is_a?(Array)
            spec.delete_at(i)
            spec.insert(i, *result)
          else # assumes that the result is a Hash
            spec[i].merge!(result)
            spec.delete('use-template')
          end
        else
          replace_uses(spec[i])
        end
      end

      spec
    end
  end
end
