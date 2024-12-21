# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2024 Joel E. Anderson
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
  #
  # +path+ is a Pathname for the source file.
  class SourceFile
    # Creates a new source file with the given path.
    def initialize(path)
      @path = path
      @contents = []
    end
  end
end
