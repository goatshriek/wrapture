# frozen_string_literal: true

module Wrapture
  # A description of a constant.
  class ConstantSpec
    def self.normalize_spec_hash(spec)
      normalized_spec = spec.dup

      normalized_spec['includes'] ||= []
      normalized_spec['includes'].uniq!

      normalized_spec
    end

    def initialize(spec)
      @spec = ConstantSpec.normalize_spec_hash spec
    end

    def declaration_includes
      @spec['includes'].dup
    end

    def definition_includes
      @spec['includes'].dup
    end

    def declaration
      "static const #{ClassSpec.typed_variable(@spec['type'], @spec['name'])}"
    end

    def definition(class_name)
      expanded_name = "#{class_name}::#{@spec['name']}"
      "const #{@spec['type']} #{expanded_name} = #{@spec['value']}"
    end
  end
end
