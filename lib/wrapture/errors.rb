# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

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

module Wrapture
  # An error from the Wrapture library
  class WraptureError < StandardError
  end

  # The spec has a key that is not valid.
  class InvalidSpecKey < WraptureError
    # Creates an InvalidSpecKey with the given message.
    def initialize(message)
      super(message)
    end
  end

  # Missing a namespace in the class spec
  class NoNamespace < WraptureError
  end

  # The spec version is not supported by this version of Wrapture.
  class UnsupportedSpecVersion < WraptureError
  end
end
