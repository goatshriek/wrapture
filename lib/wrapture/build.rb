# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025 Joel E. Anderson
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

require 'pathname'
require 'wrapture/build/cmake_build'
require 'wrapture/build/pyproject_build'
require 'wrapture/build/python_build'

module Wrapture
  # A build system for compiling and packaging source code.
  #
  # Classes can use this module by implementing +source_set+ as a +SourceSet+
  # instance, as well as +build_sources+ which is the subset of the sources that
  # are only for the build system (such as a Makefile).
  module Build
    # Creates a build instance from a hash.
    def self.from_hash(spec)
      unless spec.key?(:build_system)
        raise(MissingSpecKey, 'build_system must be specified')
      end

      case spec[:build_system]
      when 'cmake'
        CmakeBuild.from_hash(spec)
      when 'pyproject'
        PyprojectBuild.from_hash(spec)
      else
        raise(InvalidSpecKey, "unsupported build system #{spec[:build_system]}")
      end
    end

    # Writes all build system sources to the file system, returning an Array of
    # the Pathnames created.
    #
    # This is useful when the build has been created to describe source files
    # that Wrapture didn't generate, but where it did generate the build system.
    # The build system files can be generated with this method, and then the
    # build command can be issued to build the existing sources.
    def save_build_sources(dir = '.')
      build_sources.map { |it| it.save(dir) }
    end
  end
end
