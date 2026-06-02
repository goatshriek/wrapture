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
  # A simple namespace that only contains named elements.
  class PlainNamespace
    include Named
    include Namespace

    # The pieces of the namespace name.
    attr_reader :name_words

    # The contents of this namespace.
    attr_reader :named_contents

    # A plain namespace is created with a name and empty contents.
    def initialize(name)
      @name_words = if name_words.is_a?(String)
                      Named.words_from_name(name_words)
                    else
                      name
                    end
      @named_contents = []
    end
  end
end
