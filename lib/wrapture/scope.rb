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
        @classes << ClassSpec.new(class_hash, scope: self)
      end
    end

    # Generates the wrapper class files for all classes in the scope.
    def generate_wrappers
      files = []

      @classes.each do |class_spec|
        files.concat(class_spec.generate_wrappers)
      end

      files
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
