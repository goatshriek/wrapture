# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2020 Joel E. Anderson
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

module Wrapture
  # the current version of Wrapture
  VERSION = '0.4.2'

  # Returns true if the version of the spec is supported by this version of
  # Wrapture. Otherwise returns false.
  def self.supports_version?(version)
    wrapture_version = Gem::Version.new(Wrapture::VERSION)
    spec_version = Gem::Version.new(version)

    spec_version <= wrapture_version
  end
end
