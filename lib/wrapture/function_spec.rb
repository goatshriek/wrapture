# frozen_string_literal: true

require 'wrapture/scope'

module Wrapture
  # A description of a function to be generated, including details about the
  # underlying implementation.
  class FunctionSpec
    # Normalizes a hash specification of a function. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and will
    # set missing keys to their default values (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup
      param_types = {}

      normalized['version'] = Wrapture.spec_version(spec)

      normalized['params'] ||= []
      normalized['params'].each do |param_spec|
        param_types[param_spec['name']] = param_spec['type']
        includes = Wrapture.normalize_includes(param_spec['includes'])
        param_spec['includes'] = includes
      end

      wrapped = normalize_wrapped_hash(spec['wrapped-function'], param_types)
      normalized['wrapped-function'] = wrapped
      if normalized['return'].nil?
        normalized['return'] = {}
        normalized['return']['type'] = 'void'
        normalized['return']['includes'] = []
      else
        includes = Wrapture.normalize_includes(spec['return']['includes'])
        normalized['return']['includes'] = includes
      end

      normalized
    end

    # Normalizes a hash specification of a wrapped function. Normalization will
    # check for things like missing keys and duplicate entries in include lists.
    def self.normalize_wrapped_hash(spec, parent_types)
      normalized = spec.dup

      normalized['params'] ||= []
      normalized['params'].each do |param_spec|
        param_spec['value'] = param_spec['name'] if param_spec['value'].nil?

        next unless param_spec['type'].nil?

        name = param_spec['name']

        if %w[equivalent-struct equivalent-struct-pointer].include?(name)
          param_spec['type'] = name
        elsif parent_types.key?(name)
          param_spec['type'] = parent_types[name]
        end
      end

      normalized['includes'] = Wrapture.normalize_includes(spec['includes'])

      normalized
    end

    # A comma-separated string of each parameter with its type, suitable for use
    # in function signatures and definitions.
    def self.param_list(spec)
      return 'void' if spec['params'].empty?

      params = []

      spec['params'].each do |param|
        params << ClassSpec.typed_variable(param['type'], param['name'])
      end

      params.join ', '
    end

    # Creates a function spec based on the provided function spec.
    #
    # The hash must have the following keys:
    # name:: the name of the function
    # params:: a list of parameter specifications
    # wrapped-function:: a hash describing the function to be wrapped
    #
    # The wrapped-function must have a 'name' key with the name of the function,
    # and a 'params' key with a list of parameters (each a hash with a 'name'
    # and 'type' key). Optionally, it may also include an 'includes' key with a
    # list of includes that are needed for this function to compile.
    #
    # The following keys are optional:
    # static:: set to true if this is a static function.
    def initialize(spec, owner = Scope.new)
      @owner = owner
      @spec = FunctionSpec.normalize_spec_hash(spec)
    end

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      includes = @spec['return']['includes'].dup
      includes.concat(param_includes)
      includes.uniq
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @spec['return']['includes'].dup
      includes.concat(@spec['wrapped-function']['includes'])
      includes.concat(param_includes)
      includes.uniq
    end

    # The signature of the function.
    def signature
      "#{@spec['name']}( #{FunctionSpec.param_list @spec} )"
    end

    # The declaration of the function.
    def declaration
      modifier_prefix = @spec['static'] ? 'static ' : ''
      "#{modifier_prefix}#{@spec['return']['type']} #{signature}"
    end

    # Gives the definition of the function to a block, line by line.
    def definition(class_name)
      return_type = @spec['return']['type']
      yield "#{return_type} #{class_name}::#{signature} {"

      wrapped_call = String.new
      wrapped_call << "return #{return_type} ( " unless return_type == 'void'
      wrapped_call << wrapped_function_call
      wrapped_call << ' )' unless return_type == 'void'
      yield "  #{wrapped_call};"
      yield '}'
    end

    private

    # A list of includes needed for the parameters of the function.
    def param_includes
      includes = []

      @spec['params'].each do |param_spec|
        includes.concat(param_spec['includes'])
      end

      includes
    end

    # Returns a call to the wrapped function
    def wrapped_function_call
      resolved_params = []

      @spec['wrapped-function']['params'].each do |param|
        resolved_params << resolve_wrapped_param(param)
      end

      "#{@spec['wrapped-function']['name']}( #{resolved_params.join(', ')} )"
    end

    def resolve_wrapped_param(param_spec)
      used_param = @spec['params'].find { |p| p['name'] == param_spec['value'] }

      if param_spec['value'] == 'equivalent-struct'
        @owner.this_struct
      elsif param_spec['value'] == 'equivalent-struct-pointer'
        @owner.this_struct_pointer
      elsif used_param && @owner.type?(used_param['type'])
        param_class = @owner.type(used_param['type'])
        param_class.cast_to(used_param['name'], param_spec['type'])
      else
        param_spec['value']
      end
    end
  end
end
