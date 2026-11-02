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
  module PythonSource
    # A class used in Python code.
    class PythonClass
      # The PythonClass which has the equivalent struct for this class in its
      # type struct, or nil if there is not one.
      attr_accessor :equivalent_class

      # The CStruct that this class wraps, or nil if it does not wrap a struct.
      attr_accessor :equivalent_struct

      # The name of the class.
      attr_reader :name

      # An Array of parent classes.
      attr_reader :parents

      # True if the type information of this class is only available at runtime.
      # An example of this case is if it inherits from a class that is purely
      # Python or is not exposed in Python's C API, such as the Exception class.
      attr_writer :runtime

      # A Python class must have a name, at a minimum.
      def initialize(name)
        @name = name

        @equivalent_class = nil
        @equivalent_struct = nil
        @parents = []
        @runtime = false

        # TODO: pick up here, using PythonClass in the wrapper
      end

      # True if the type information of this class is only available at runtime.
      def runtime?
        @runtime
      end

      # The PyTypeObject C struct used to describe this class type.
      def type_struct
        nil
      end
    end
  end
end
