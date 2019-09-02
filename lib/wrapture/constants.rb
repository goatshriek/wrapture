# frozen_string_literal: true

module Wrapture
  # A string denoting an equivalent struct type or value.
  EQUIVALENT_STRUCT_KEYWORD = 'equivalent-struct'

  # A string denoting a pointer to an equivalent struct type or value.
  EQUIVALENT_POINTER_KEYWORD = 'equivalent-struct-pointer'

  # A list of all keywords.
  KEYWORDS = [EQUIVALENT_STRUCT_KEYWORD, EQUIVALENT_POINTER_KEYWORD].freeze
end
