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
  # A context represents a specific collection of specs and namespaces. This
  # provides the information needed to resolve relative references within specs
  # during wrapper generation. For example, a function being used as a method
  # in a class will resolve the type of the self/this instance using the
  # context.
  #
  # A Context has two attributes: a set of Named elements called contents, and
  # a Context instance named parent. Note that while a Context is aware of the
  # Context which contains it, it is not aware of any Contexts that it might
  # contain. This is to ensure that the context chain is always walked in a
  # specific to general direction.
  #
  # When a context resolves a name, it starts by searching its own contents,
  # and if nothing is found then it defers to the parent Context.
  class Context
    # A Set of Named elements that this Context directly contains.
    attr_reader :contents

    # A Context that contains this one. If this is nil, then this Context is
    # the root.
    attr_reader :parent

    # A new Context has no contents, but may have a +parent+ Context.
    def initialize(parent: nil)
      @contents = Set.new
      @parent = parent
    end
  end
end
