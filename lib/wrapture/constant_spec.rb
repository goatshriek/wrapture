# frozen_string_literal: true

require 'wrapture/normalize'

module Wrapture
  # A description of a constant.
  class ConstantSpec
    # Normalizes a hash specification of a constant. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and
    # will set missing keys to their default value (for example, an empty list
    # if no includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup

      normalized['version'] = Wrapture.spec_version(spec)
      normalized['includes'] = Wrapture.normalize_includes spec['includes']

      normalized
    end

    # Creates a constant spec based on the provided hash spec
    #
    # The hash must have the following keys:
    # name:: the name of the constant
    # type:: the type of the constant
    # value:: the value to assign to the constant
    # includes::  a list of includes that need to be added in order for this
    # constant to be valid (for example, includes for the type and value).
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this constant
    def initialize(spec)
      @spec = ConstantSpec.normalize_spec_hash spec
    end

    # A list of includes needed for the declaration of this constant.
    def declaration_includes
      @spec['includes'].dup
    end

    # A list of includes needed for the definition of this constant.
    def definition_includes
      @spec['includes'].dup
    end

    # The declaration of this constant.
    def declaration
      "static const #{ClassSpec.typed_variable(@spec['type'], @spec['name'])}"
    end

    # The definition of this constant.
    def definition(class_name)
      expanded_name = "#{class_name}::#{@spec['name']}"
      "const #{@spec['type']} #{expanded_name} = #{@spec['value']}"
    end
  end
end
