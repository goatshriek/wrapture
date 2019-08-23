# frozen_string_literal: true

module Wrapture
  # An error from the Wrapture library
  class WraptureError < StandardError
  end

  # Missing a namespace in the class spec
  class NoNamespace < WraptureError
  end

  # The spec version is not supported by this version of Wrapture.
  class UnsupportedSpecVersion < WraptureError
  end
end
