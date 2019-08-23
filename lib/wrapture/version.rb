# frozen_string_literal: true

module Wrapture
  # the current version of Wrapture
  VERSION = '0.3.0'

  # Returns true if the version of the spec is supported by this version of
  # Wrapture. Otherwise returns false.
  def self.supports_version?(version)
    wrapture_version = Gem::Version.new(Wrapture::VERSION)
    spec_version = Gem::Version.new(version)

    spec_version <= wrapture_version
  end
end
