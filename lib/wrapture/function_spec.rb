# frozen_string_literal: true

require 'wrapture/scope'
require 'wrapture/wrapped_function_spec'

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
    def initialize(spec, owner = Scope.new, constructor: false,
                   destructor: false)
      @owner = owner
      @spec = FunctionSpec.normalize_spec_hash(spec)
      @wrapped = WrappedFunctionSpec.new(spec['wrapped-function'])
      @structor = constructor || destructor
    end

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      includes = @spec['return']['includes'].dup
      includes.concat(param_includes)
      includes.uniq
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @wrapped.includes
      includes.concat(@spec['return']['includes'])
      includes.concat(param_includes)
      includes.uniq
    end

    # A comma-separated list of parameters and resolved types fit for use in a
    # function signature or declaration.
    def param_list
      return 'void' if @spec['params'].empty?

      params = []

      @spec['params'].each do |param|
        type = resolve_type(param['type'])
        params << ClassSpec.typed_variable(type, param['name'])
      end

      params.join(', ')
    end

    # Gives an expression for calling a given parameter within this function.
    # Equivalent structs and pointers are resolved, as well as casts between
    # types if they are known within the scope of this function.
    def resolve_wrapped_param(param_spec)
      used_param = @spec['params'].find { |p| p['name'] == param_spec['value'] }

      if param_spec['value'] == EQUIVALENT_STRUCT_KEYWORD
        @owner.this_struct
      elsif param_spec['value'] == EQUIVALENT_POINTER_KEYWORD
        @owner.this_struct_pointer
      elsif used_param &&
            @owner.type?(used_param['type']) &&
            !param_spec['type'].nil?
        param_class = @owner.type(used_param['type'])
        param_class.cast_to(used_param['name'], param_spec['type'])
      else
        param_spec['value']
      end
    end

    # The signature of the function.
    def signature
      "#{@spec['name']}( #{param_list} )"
    end

    # The declaration of the function.
    def declaration
      return signature if @structor

      modifier_prefix = @spec['static'] ? 'static ' : ''
      "#{modifier_prefix}#{@spec['return']['type']} #{signature}"
    end

    # Gives the definition of the function to a block, line by line.
    def definition(class_name)
      return_type = @spec['return']['type']
      return_prefix = @structor ? '' : "#{return_type} "
      yield "#{return_prefix}#{class_name}::#{signature} {"

      wrapped_call = String.new
      wrapped_call << "return #{return_type} ( " unless return_type == 'void'
      wrapped_call << @wrapped.call_from(self)
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

    # A resolved type name.
    def resolve_type(type)
      if type == EQUIVALENT_STRUCT_KEYWORD
        "struct #{@owner.struct_name}"
      elsif type == EQUIVALENT_POINTER_KEYWORD
        "struct #{@owner.struct_name} *"
      else
        type
      end
    end
  end
end
