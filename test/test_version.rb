# frozen_string_literal: true

require 'helper'

require 'minitest/autorun'
require 'wrapture'

class VersionTest < Minitest::Test
  def test_gemspec_date
    spec = Gem::Specification.load('wrapture.gemspec')

    date_regex = /^## \[(\d+\.\d+\.\d+)\] - (\d{4}-\d{2}-\d{2})/
    File.open('ChangeLog.md').each do |line|
      date_regex.match(line) do |match_data|
        if match_data[1] == spec.version.to_s
          assert_equal(match_data[2], spec.date.strftime('%Y-%m-%d'),
                       'the changelog date and gem date do not match')
        end
      end
    end
  end

  def test_gemspec_version
    spec = Gem::Specification.load('wrapture.gemspec')
    spec_version = spec.version.to_s
    assert_equal Wrapture::VERSION, spec_version
  end

  def test_version_syntax
    assert_match(/\d+\.\d+\.\d+/, Wrapture::VERSION)
  end
end
