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
      normalized = spec.dup

      normalized['params'] ||= []
      normalized['wrapped-function']['params'] ||= []

      original_includes = spec['wrapped-function']['includes']
      includes = Wrapture.normalize_includes original_includes
      normalized['wrapped-function']['includes'] = includes
      if normalized['return'].nil?
        normalized['return'] = {}
        normalized['return']['type'] = 'void'
        normalized['return']['includes'] = []
      else
        includes = Wrapture.normalize_includes spec['return']['includes']
        normalized['return']['includes'] = includes
      end

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
