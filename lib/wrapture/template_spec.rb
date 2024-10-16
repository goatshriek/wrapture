# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2020-2023 Joel E. Anderson
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
  # needing to repeat them everywhere they're needed. For example, if the error
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
  # In templates that don't have any parameters, you can save a small bit of
  # typing by simply setting the value of the +use-template+ member to the name
  # of the template directly. So, the previous invocation would become this:
  #
  #  classes:
  #    - name: "ClassA"
  #      use-template: "standard-class-properties"
  #    - name: "ClassB"
  #      use-template: "standard-class-properties"
  #
  # == Usage in Arrays
  # In some cases, you may want a template to expand to an array of elements
  # that are added to an existing array. This can be accomplished by invoking
  # the template in its own list element and making sure that the
  # +use-template+ member is the only member of the hash. This will result in
  # the template result being inserted into the list at the point of the
  # template invocation. Consider this example specification snippet:
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
  # == Usage in other Templates
  # Templates may reference other templates within themselves. There is no limit
  # to this nesting, which means that it is quite possible for a careless
  # developer to get himself into trouble, for example by recursively
  # referencing a template from itself. Responsible usage of this functionality
  # is left to the users.
  #
  # There are no guarantees made about the order in which templates are
  # expanded. This is an attempt to keep template usage simple and direct.
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
    # Replaces all instances of the given templates in the provided spec. This
    # is done recursively until no more changes can be made. Returns true if
    # any changes were made, false otherwise.
    def self.replace_all_uses(spec, *templates)
      return false unless spec.is_a?(Hash) || spec.is_a?(Array)

      changed = false
      loop do
        changes = templates.collect do |temp|
          temp.replace_uses(spec)
        end

        changed = true if changes.any?

        break unless changes.any?
      end

      changed
    end

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
      case spec
      when Hash
        replace_param_in_hash(spec, param_name, param_value)
      when Array
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

    # True if the given spec is a reference to this template that will be
    # completely replaced by the template. A direct use can be recognized as
    # a hash with only a 'use-template' key and no others.
    def direct_use?(spec)
      use?(spec) && spec.length == 1
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
    # the given spec. Returns true if any changes were made, false otherwise.
    #
    # Recursive template uses will not be replaced by this function. If
    # multiple replacements are needed, then you will need to call this function
    # multiple times.
    def replace_uses(spec)
      case spec
      when Hash
        replace_uses_in_hash(spec)
      when Array
        replace_uses_in_array(spec)
      else
        false
      end
    end

    # True if the given spec is a reference to this template.
    def use?(spec)
      return false unless spec.is_a?(Hash) && spec.key?(TEMPLATE_USE_KEYWORD)

      invocation = spec[TEMPLATE_USE_KEYWORD]
      case invocation
      when String
        invocation == name
      when Hash
        unless invocation.key?('name')
          error_message = "invocations of #{TEMPLATE_USE_KEYWORD} must have " \
                          'a name member'
          raise InvalidTemplateUsage, error_message
        end

        invocation['name'] == name
      else
        error_message = "#{TEMPLATE_USE_KEYWORD} must either be a String or " \
                        'a Hash'
        raise InvalidTemplateUsage, error_message
      end
    end

    private

    # Replaces a single use of the template in a Hash object.
    def merge_use_with_hash(use)
      result = instantiate(use['use-template']['params'])

      error_message = "template #{name} was invoked in a Hash with other " \
                      'keys, but does not resolve to a hash itself'
      raise InvalidTemplateUsage, error_message unless result.is_a?(Hash)

      use.merge!(result) { |_, oldval, _| oldval }
      use.delete(TEMPLATE_USE_KEYWORD)
    end

    # Replaces all references to this template with an instantiation of it in
    # the given spec, assuming it is a hash. Returns true if any changes were
    # made, false otherwise.
    def replace_uses_in_hash(spec)
      changes = []

      if use?(spec)
        merge_use_with_hash(spec) if use?(spec)
        changes << true
      end

      spec.each_pair do |key, value|
        if direct_use?(value)
          spec[key] = instantiate(value[TEMPLATE_USE_KEYWORD]['params'])
          changes << true
        else
          changes << replace_uses(value)
        end
      end

      changes.any?
    end

    # Replaces all references to this template with an instantiation of it in
    # the given spec, assuming it is an array. Returns true if any changes were
    # made, false otherwise.
    def replace_uses_in_array(spec)
      changes = []

      spec.dup.each_index do |i|
        if direct_use?(spec[i])
          result = instantiate(spec[i][TEMPLATE_USE_KEYWORD]['params'])
          spec.delete_at(i)
          if result.is_a?(Array)
            spec.insert(i, *result)
          else
            spec.insert(i, result)
          end
          changes << true
        elsif use?(spec[i])
          merge_use_with_hash(spec[i])
          changes << true
        else
          changes << replace_uses(spec[i])
        end
      end

      changes.any?
    end
  end
end
