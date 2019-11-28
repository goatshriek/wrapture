# frozen_string_literal: true

module Wrapture
  # A description of a function to be wrapped by another language.
  class WrappedFunctionSpec
    # Normalizes a hash specification of a wrapped function. Normalization will
    # check for things like invalid keys, duplicate entries in include lists,
    # and will set missing keys to their default values (for example, an empty
    # list if no includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      normalized['params'] ||= []
      normalized['params'].each do |param_spec|
        param_spec['value'] = param_spec['name'] if param_spec['value'].nil?
      end

      normalized['includes'] = Wrapture.normalize_includes(spec['includes'])

      normalized['error-check'] ||= {}
      normalized['error-check']['rules'] ||= []

      normalized
    end

    # Creates a wrapped function spec based on the provided spec.
    #
    # The hash must have the following keys:
    # name:: the name of the wrapped function
    # params:: a list of parameters to supply when calling
    #
    # Each member of the params list must be a hash, with a mandatory key of
    # 'value' holding the value to be supplied as the parameter. If only a
    # 'name' key is provided, this will be used as the value. A 'type' may be
    # supplied as well, and is necessary if an equivalent struct or pointer is
    # to be supplied as the value so that casting can be performed correctly.
    #
    # The following key is optional:
    # includes:: a list of includes needed for this function
    def initialize(spec)
      @spec = self.class.normalize_spec_hash(spec)

      @error_rules = @spec['error-check']['rules'].map do |rule_spec|
        RuleSpec.new(rule_spec)
      end

      @error_action = ActionSpec.new(@spec['error-check']['error-action'])
    end

    # Generates a function call from a provided FunctionSpec. Paremeters and
    # types are resolved using this function's context.
    def call_from(function_spec)
      resolved_params = []

      @spec['params'].each do |param|
        resolved_params << function_spec.resolve_wrapped_param(param)
      end

      "#{@spec['name']}( #{resolved_params.join(', ')} )"
    end

    # A list of includes required for this function call.
    def includes
      @spec['includes'].dup
    end
  end
end
