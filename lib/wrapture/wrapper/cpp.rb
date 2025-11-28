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

module Wrapture
  module Wrapper
    # Utilities for wrappers that use C++ as either a from or to language.
    module Cpp
      # Makes a decorated version of the given name so that it is unique among
      # other names based on the C++ language. This is done by prepending "cpp"
      # to the name: for example "MyLib" will become "CppMyLib".
      def self.decorate_name_words(name_words)
        ['cpp'] + name_words
      end
    end
  end
end
