# frozen_string_literal: true

module Wrapture
  # A description of a struct.
  class StructSpec
    # Normalizes a hash specification of a struct. Normalization will check for
    # things like invalid keys, duplicate entries in include lists, and will set
    # missing keys to their default value (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      normalized = spec.dup
      normalized.default = []

      normalized['includes'] = Wrapture.normalize_includes spec['includes']

      normalized['members'] ||= []

      normalized
    end

    # A declaration of the struct with the given variable name.
    def declaration(name)
      "struct #{@spec['name']} #{name}"
    end

    # A list of includes required for this struct.
    def includes
      @spec['includes'].dup
    end

    # Creates a struct spec based on the provided spec hash.
    #
    # The hash must have the following keys:
    # name:: the name of the struct
    #
    # The following keys are optional:
    # includes:: a list of includes required for the struct
    # members:: a list of the members of the struct, each with a type and name
    # field
    def initialize(spec)
      @spec = StructSpec.normalize_spec_hash spec
    end

    # A string containing the typed members of the struct, separated by commas.
    def member_list
      members = []

      @spec['members'].each do |member|
        members << ClassSpec.typed_variable(member['type'], member['name'])
      end

      members.join ', '
    end

    # The members of the struct
    def members
      @spec['members']
    end

    # True if there are members included in the struct specification.
    def members?
      !@spec['members'].empty?
    end

    # The name of this struct
    def name
      @spec['name']
    end

    # A declaration of a pointer to the struct with the given variable name.
    def pointer_declaration(name)
      "struct #{@spec['name']} *#{name}"
    end
  end
end
