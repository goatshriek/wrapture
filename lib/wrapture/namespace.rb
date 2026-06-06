# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2026 Joel E. Anderson
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
  # Namespaces represent elements that contain elements within them. This may be
  # a purely logical construct as in PlainNamespace, or may be some other type
  # that contains elements, such as ClassSpec. Anything contained within a
  # Namespace must be Named.
  #
  # Namespaces must have an attribute named +named_contents+ which is an Array
  # holding the contents of the namespace. Note that this array could include
  # other namespaces.
  module Namespace
    # Appends Named +item+ to the namespace.
    def <<(item)
      named_contents << item

      self
    end

    # All classes in the namespace.
    def classes
      named_contents.grep(ClassSpec)
    end

    # All constants in the namespace.
    def constants
      named_contents.grep(ConstantSpec)
    end

    # All enums in the namespace.
    def enums
      named_contents.grep(EnumSpec)
    end

    # All function in the namespace.
    #
    # This is not a recursive enumeration. For example, functions in classes
    # within the namespace are not returned.
    def functions
      named_contents.grep(FunctionSpec)
    end
  end
end
