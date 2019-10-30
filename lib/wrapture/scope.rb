# frozen_string_literal: true

module Wrapture
  # Describes a scope of one or more class specifications.
  class Scope
    # A list of classes currently in the scope.
    attr_reader :classes

    # Creates an empty scope with no classes in it.
    def initialize(spec = nil)
      @classes = []

      return if spec.nil? || !spec.key?('classes')

      @version = Wrapture.spec_version(spec)
      spec['classes'].each do |class_hash|
        ClassSpec.new(class_hash, scope: self)
      end
    end

    # Adds a class specification to the scope.
    #
    # This does not set the scope as the owner of the class. This must be done
    # during the construction of the class spec.
    def <<(spec)
      @classes << spec if spec.is_a?(ClassSpec)
    end

    # Generates the wrapper class files for all classes in the scope.
    def generate_wrappers
      files = []

      @classes.each do |class_spec|
        files.concat(class_spec.generate_wrappers)
      end

      files
    end

    # A list of ClassSpecs in this scope that are overloads of the given class.
    def overloads(parent)
      @classes.select { |class_spec| class_spec.overloads?(parent) }
    end

    # True if there is an overload of the given class in this scope.
    def overloads?(parent)
      @classes.any? { |class_spec| class_spec.overloads?(parent) }
    end

    # Returns the ClassSpec for the given type in the scope.
    def type(type)
      @classes.find { |class_spec| class_spec.name == type }
    end

    # Returns true if the given type is in the scope.
    def type?(type)
      @classes.each do |class_spec|
        return true if class_spec.name == type
      end

      false
    end
  end
end
