# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2025-2026 Joel E. Anderson
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
  # CLI support for Wrapture invocations.
  module Config
    # Configuration information for a single wrap command.
    class WrapConfig
      # A WrapConfig instance describes the contexts that should be wrapped by
      # an invocation, as well as the input and output language paths. Other
      # details include parallelization, how to report progress, and output
      # details.
      def initialize
        @contexts = []
        @output = Pathname.pwd
        @paths = []
      end

      # A list of ClassSpec instances with class hashes to wrap.
      attr_accessor :contexts

      # A Pathname for the output directory for generated wrappers.
      attr_accessor :output

      # A list of Path instances with the wrapping paths to follow.
      attr_accessor :paths
    end
  end
end
