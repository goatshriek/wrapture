# frozen_string_literal: true

require 'helper'

require 'minitest/autorun'
require 'wrapture'

class VersionTest < Minitest::Test
  def test_gemspec_version
    spec = Gem::Specification.load('wrapture.gemspec')
    spec_version = spec.version.to_s
    assert_equal Wrapture::VERSION, spec_version
  end

  def test_version_syntax
    assert_match(/\d+\.\d+\.\d+/, Wrapture::VERSION)
  end
end
