# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2021 Joel E. Anderson
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
  # A wrapper that generates Python wrappers for given specs.
  class PythonWrapper
    # Generates C source files that form an extension module of Python with
    # the functionality of this instance's spec, returning a list of the
    # files generated. +dir+ specifies the directory that the files should
    # be written into. The default is the current working directory.
    def write_files(dir: Dir.pwd)
      # todo
    end
  end
end
