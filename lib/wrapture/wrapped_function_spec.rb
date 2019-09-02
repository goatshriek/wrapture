# frozen_string_literal: true

module Wrapture
  # A description of a function to be wrapped by another language.
  class WrappedFunctionSpec
    # Normalizes a hash specification of a wrapped function. Normalization will
    # check for things like invalid keys, duplicate entries in include lists,
    # and will set missing keys to their default values (for example, an empty
    # list if no includes are given).
    def self.normalize_spec_hash(spec, parent_types)
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
  end
end
