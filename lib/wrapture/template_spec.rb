# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
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
#++

module Wrapture
  # A template that can be referenced in other specs.
  #
  # Templates provide a way to re-use common specification portions without
  # needing to repeat it in each portion it is needed. For example, if the error
  # handling code within a wrapped library is the same for most functions, it
  # can be defined once in a template and then simply referenced in each
  # function specification that needs it. Not only does this reduce the size of
  # the specifications, but it also allows changes to be made in one place
  # instead of many.
  #
  # = Basic Usage
  #
  # Templates are defined in a top-level +templates+ member of a specification,
  # which holds an array of templates. Each template has only two properties:
  # +name+ which holds the name of the template that is used to invoke it from
  # other specifications, and +value+ which holds the object(s) to insert when
  # the template is used.
  #
  # Templates can be used at any point in a specification by including a Hash
  # member named +use-template+ which is itself a Hash containing a +name+
  # member and optionally a parameter list (see below). When a spec is created
  # in a scope that has a template with the given name, the +use-template+
  # object will be replaced with the template contents. Other members of the
  # Hash will be left intact.
  #
  # To illustrate, consider a template defined with some normal class properties
  # for a library:
  #
  #   name: "standard-class-properties"
  #   value:
  #     namespace: "wrapturedemo"
  #     type: "pointer"
  #
  # This could then used in a class specification like this:
  #
  #   classes:
  #     - name: "ClassA"
  #       use-template:
  #         name: "standard-class-properties"
  #     - name: "ClassB"
  #       use-template:
  #         name: "standard-class-properties"
  #
  # Which would result in an effective class specification of this:
  #
  #   classes:
  #     - name: "ClassA"
  #       namespace: "wrapturedemo"
  #       type: "pointer"
  #     - name: "ClassB"
  #       namespace: "wrapturedemo"
  #       type: "pointer"
  #
  # Note that the properties included in the template were added to the other
  # members of the object. If there is a conflict between members, the member of
  # the invoking specification will override the template's member.
  #
  # == Usage in Arrays
  # In some cases, you may want a template to expand to an array of elements
  # that are added to an existing array. This can be accomplished by invoking
  # the template in it's own list element and making sure that the
  # +use-template+ member is the only member of the hash. This will result in
  # the template result being inserted into the list at the point of the
  # template invocation. Consider this example specification file snippet:
  #
  #   templates:
  #     - name: "default-includes"
  #       value:
  #         - "struct_decls.h"
  #         - "error_handling.h"
  #         - "macros.h"
  #   classes:
  #     - name: "StupendousMan"
  #       equivalent-struct:
  #         name: "stupendous_man"
  #         includes:
  #           - "man.h"
  #           - use-template:
  #               name: "default-includes"
  #           - "stupendous.h"
  #
  # This would result in an include list containing this:
  #
  #   includes:
  #     - "man.h"
  #     - "struct_decls.h"
  #     - "error_handling.h"
  #     - "macros.h"
  #     - "stupendous.h"
  #
  # Note that this behavior means that if your intention is to make a list
  # element itself include a list, then you will need to put the template
  # invocation into its own list, like this:
  #
  #   my_list:
  #     - "element-1"
  #     - "element-2"
  #     -
  #       - use-template:
  #           name: "list-template"
  #
  # = Parameters
  #
  # Templates may contain any number of parameters that can be supplied upon
  # invocation. The supplied parameters are then used to replace values in the
  # template upon template invocation. This allows templates to be reusable in a
  # wider variety of situations where they may be a small number of differences
  # between invocations, but not significant.
  #
  # Paremeters are signified within a template by using a hash that has a
  # +is-param+ member set to true, and a +name+ member containing the name of
  # the parameter. In the template invocation, a +params+ member is supplied
  # which contains a list of parameter names and values to substitute for them.
  #
  # A simple use of template parameters is shown here, where a template is used
  # to wrap functions which differ only in the name of the underlying wrapped
  # function:
  #
  #   templates:
  #     - name: "simple-function"
  #       value:
  #         wrapped-function:
  #           name:
  #             is-param: true
  #             name: "wrapped-function"
  #           params:
  #             - value: "equivalent-struct-pointer"
  #   classes:
  #     - name: "StupendousMan"
  #       functions:
  #         - name: "crawl"
  #           use-template:
  #             name: "simple-function"
  #             params:
  #               name: "wrapped-function"
  #               value: "stupendous_man_crawl"
  #         - name: "walk"
  #           use-template:
  #             name: "simple-function"
  #             params:
  #               name: "wrapped-function"
  #               value: "stupendous_man_walk"
  #         - name: "run"
  #           use-template:
  #             name: "simple-function"
  #             params:
  #               name: "wrapped-function"
  #               value: "stupendous_man_run"
  #
  # The above would result in a class specification of this:
  #
  #  name: "StupendousMan"
  #  functions:
  #    - name: "crawl"
  #      wrapped-function:
  #            name: "stupendous_man_crawl"
  #            params:
  #              - value: "equivalent-struct-pointer"
  #    - name: "walk"
  #      wrapped-function:
  #            name: "stupendous_man_walk"
  #            params:
  #              - value: "equivalent-struct-pointer"
  #    - name: "run"
  #      wrapped-function:
  #            name: "stupendous_man_run"
  #            params:
  #              - value: "equivalent-struct-pointer"
  #
  # == Parameter Replacement
  # The rules for parameter replacement are not as complex as for template
  # invocation, as they are intended to hold single values rather than
  # heirarchical object structures. Replacement of a parameter simply replaces
  # the hash containing the +is-param+ member with the given parameter of the
  # same name. Objects may be supplied instead of single values, but they will
  # be inserted directly into the position rather than merged with other hash or
  # array members. If the more complex merging functionality is needed, then
  # consider invoking a template instead of using a parameter.
  class TemplateSpec
    # True if the provided spec is a template parameter with the given name.
    def self.param?(spec, param_name)
      spec.is_a?(Hash) &&
        spec.key?('is-param') &&
        spec['is-param'] &&
        spec['name'] == param_name
    end

    # Creates a new spec based on the given one with all instances of a
    # parameter with the given name replaced with the given value.
    def self.replace_param(spec, param_name, param_value)
      new_spec = Marshal.load(Marshal.dump(spec))
      replace_param!(new_spec, param_name, param_value)
    end

    # Replaces all instances of a parameter with the given name with the given
    # value in the provided spec.
    def self.replace_param!(spec, param_name, param_value)
      if spec.is_a?(Hash)
        replace_param_in_hash(spec, param_name, param_value)
      elsif spec.is_a?(Array)
        replace_param_in_array(spec, param_name, param_value)
      else
        spec
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

      spec
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

      spec
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
        result = instantiate(spec['use-template']['params'])
        spec.merge!(result) { |_, oldval, _| oldval }
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
