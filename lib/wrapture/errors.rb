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
  # An error from the Wrapture library
  class WraptureError < StandardError
  end

  # A documentation string is invalid.
  class InvalidDoc < WraptureError
  end

  # A template has been invoked in an unsupported way.
  class InvalidTemplateUsage < WraptureError
  end

  # The spec has a key that is not valid.
  class InvalidSpecKey < WraptureError
    # Creates an InvalidSpecKey with the given message. A list of valid values
    # may optionally be passed to +valid_keys+ which will be added to the end
    # of the message.
    def initialize(message, valid_keys: [])
      complete_message = message.dup

      unless valid_keys.empty?
        complete_message << ' (valid values are \''
        complete_message << valid_keys.join('\', \'')
        complete_message << '\')'
      end

      super(complete_message)
    end
  end

  # The spec is missing a key that is required.
  class MissingSpecKey < WraptureError
  end

  # Missing a namespace in the class spec
  class MissingNamespace < WraptureError
  end

  # The spec cannot be defined due to missing information.
  class UndefinableSpec < WraptureError
  end

  # The spec version is not supported by this version of Wrapture.
  class UnsupportedSpecVersion < WraptureError
  end

  # A wrapper encountered a problem during wrap generation.
  class WrapError < WraptureError
  end
end
