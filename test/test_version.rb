# frozen_string_literal: true

require 'helper'

require 'minitest/autorun'
require 'wrapture'

class VersionTest < Minitest::Test
  def test_version_syntax
    assert_match(/\d+\.\d+\.\d+/, Wrapture::VERSION)
  end
end
