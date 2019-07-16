# frozen_string_literal: true

module Wrapture
  # Describes a scope of one or more class specifications.
  class Scope
    # Creates an empty scope with no classes in it.
    def initialize
      @classes = []
    end

    # Adds a spec to the scope
    def add(spec)
      @classes.push(spec) if spec.is_a ClassSpec
    end

    # Returns true if the scope contains the given type.
    def type?(type)
      @classes.each do |class_spec|
        return true if class_spec.name == type
      end
    end
  end
end
