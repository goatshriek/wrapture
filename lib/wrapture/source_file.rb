# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2024-2025 Joel E. Anderson
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
  # A generated source code file.
  #
  # A source file could be wrapper source code, build system files, scripts,
  # markup, or other supporting files for a generated wrapper.
  class SourceFile
    # An enumerable of Strings that make up the contents of the source file.
    attr_reader :contents

    # The Pathname of the source file.
    attr_reader :path

    # Creates a new source file with the given path.
    #
    # +path+ is a Pathname for the source file. If it is a String, then it is
    # used to create a new Pathname.
    def initialize(path)
      @path = case path
              when String
                Pathname.new(path)
              else
                path
              end
      @contents = []
    end

    # Compares the filename and contents of a source file for equality.
    def ==(other)
      @path == other.path && @contents == other.contents
    end

    # Alias to support usage as a Hash key.
    alias eql? ==

    # Hash the path and contents.
    def hash
      [@path, @contents].hash
    end

    # Adds a raw line of code to a source file, followed by a newline.
    def puts(line)
      @contents << line
      @contents << "\n"
    end
  end
end
