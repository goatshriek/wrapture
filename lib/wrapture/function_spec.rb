# frozen_string_literal: true

module Wrapture
  # A description of a function to be generated, including details about the
  # underlying implementation.
  class FunctionSpec
    # Normalizes a hash specification of a function. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and will
    # set missing keys to their default values (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      normalized_spec = spec.dup

      normalized_spec['params'] ||= []
      normalized_spec['wrapped-function']['params'] ||= []
      normalized_spec['wrapped-function']['includes'] ||= []

      if normalized_spec['return'].nil?
        normalized_spec['return'] = {}
        normalized_spec['return']['type'] = 'void'
      end

      normalized_spec['return']['includes'] ||= []

      normalized_spec
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
    # wrapped-function:: a description of the function to be wrapped.
    #
    # The following keys are optional:
    # static:: set to true if this is a static function.
    def initialize(spec, owner)
      @owner = owner
      @spec = FunctionSpec.normalize_spec_hash(spec)
    end

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      @spec['return']['includes'].dup
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @spec['return']['includes'].dup
      includes.concat @spec['wrapped-function']['includes']

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
      wrapped_call << @owner.function_call(@spec['wrapped-function'])
      wrapped_call << ' )' unless return_type == 'void'
      yield "  #{wrapped_call};"
      yield '}'
    end
  end
end
