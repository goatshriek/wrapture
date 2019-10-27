# frozen_string_literal: true

module Wrapture
  # An error from the Wrapture library
  class WraptureError < StandardError
  end

  # The spec has a key that is not valid.
  class InvalidSpecKey < WraptureError
    # Creates an InvalidSpecKey with the given message.
    def initialize(message)
      super(message)
    end
  end

  # Missing a namespace in the class spec
  class NoNamespace < WraptureError
  end

  # The spec version is not supported by this version of Wrapture.
  class UnsupportedSpecVersion < WraptureError
  end
end
