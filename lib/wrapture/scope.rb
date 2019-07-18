# frozen_string_literal: true

module Wrapture
  # Describes a scope of one or more class specifications.
  class Scope
    attr_reader :classes

    # Creates an empty scope with no classes in it.
    def initialize(spec = nil)
      @classes = []

      return if spec.nil? || !spec.key?('classes')

      spec['classes'].each do |class_hash|
        @classes << ClassSpec.new(class_hash, self)
      end
    end

    # Adds a spec to the scope.
    def add(spec)
      @classes.push(spec) if spec.is_a? ClassSpec
    end

    # Returns a ClassSpec for the given type if it is in the scope.
    def type?(type)
      @classes.each do |class_spec|
        return class_spec if class_spec.name == type
      end

      false
    end
  end
end
