# frozen_string_literal: true

module Wrapture
  # Normalizes an include list for an element. A single string will be converted
  # into an array containing the single string, and a nil will be converted to
  # an empty array.
  def self.normalize_includes(includes)
    if includes.nil?
      []
    elsif includes.is_a? String
      [includes]
    else
      includes.uniq
    end
  end
end
