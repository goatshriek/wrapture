# frozen_string_literal: true

module Wrapture
  ##
  # A description of a function to be generated, including details about the
  # underlying implementation.
  class FunctionSpec
    def self.normalize_spec_hash(spec)
      normalized_spec = spec.dup

      normalized_spec['params'] ||= []
      normalized_spec['wrapped-function']['params'] ||= []

      if normalized_spec['return'].nil?
        normalized_spec['return'] = {}
        normalized_spec['return']['type'] = 'void'
      end

      normalized_spec['return']['includes'] ||= []

      normalized_spec
    end

    def self.param_list(spec)
      return 'void' if spec['params'].empty?

      params = []

      spec['params'].each do |param|
        params << ClassSpec.typed_variable(param['type'], param['name'])
      end

      params.join ', '
    end

    def initialize(spec, owner)
      @owner = owner
      @spec = FunctionSpec.normalize_spec_hash(spec)
    end

    def declaration_includes
      @spec['return']['includes'].dup
    end

    def definition_includes
      includes = @spec['return']['includes'].dup
      includes.concat @spec['wrapped-function']['includes']

      includes.uniq
    end

    def signature
      "#{@spec['name']}( #{FunctionSpec.param_list @spec} )"
    end

    def declaration
      modifier_prefix = @spec['static'] ? 'static' : ''
      "#{modifier_prefix}#{@spec['return']['type']} #{signature}"
    end

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
