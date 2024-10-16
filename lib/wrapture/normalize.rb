# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019 Joel E. Anderson
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
  # Normalizes a spec key to be boolean, raising an error if it is not. Keys
  # that are not present are defaulted to false.
  def self.normalize_boolean(spec, key)
    is_boolean = [true, false].include?(spec[key])
    error_msg = "'#{key}' key may only be true or false"
    raise(InvalidSpecKey, error_msg) unless !spec.key?(key) || is_boolean

    spec.key?(key) && spec[key]
  end

  # Sets a spec key to be boolean, raising an error if an issue is encountered.
  # Keys that are not present are defaulted to false.
  def self.normalize_boolean!(spec, key)
    spec[key] = normalize_boolean(spec, key)
  end

  # Normalizes an array in a spec, such as an include list for an element. A
  # single string will be converted into an array containing the single string,
  # and a nil will be converted to an empty array.
  def self.normalize_array(entry)
    if entry.nil?
      []
    elsif entry.is_a? String
      [entry]
    else
      entry.uniq
    end
  end

  # Returns the spec version for the provided spec. If the version is not
  # provided in the spec, the newest version that the spec is compliant with
  # will be returned instead.
  #
  # If this spec uses a version unsupported by this version of Wrapture or the
  # spec is otherwise invalid, an exception is raised.
  def self.spec_version(spec)
    if spec&.key?('version') && !Wrapture.supports_version?(spec['version'])
      raise UnsupportedSpecVersion
    end

    if spec&.key?('version')
      spec['version']
    else
      Wrapture::VERSION
    end
  end
end
