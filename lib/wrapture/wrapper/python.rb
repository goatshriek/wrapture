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
  module Wrapper
    # Utilities for wrappers that use Python as either a from or to language.
    module Python
      # The decorated name words for Named instance +named+.
      def self.decorate_name(named)
        decorate_name_words(named.name_words)
      end

      # Makes a decorated version of the given name so that it is unique among
      # other names based on the C++ language. This is done by prepending "cpp"
      # to the name: for example "MyLib" will become "CppMyLib".
      def self.decorate_name_words(name_words)
        ['py'] + name_words
      end

      # The effective Python module name for +namespace+.
      def self.module_name(namespace)
        if namespace.source.key?(:python)
          if namespace.source[:python].key?(:name)
            return namespace.source[:python][:name]
          elsif namespace.source[:python].key?(:decorate_name) &&
                namespace.source[:python][:decorate_name]
            return Named.snake_case_name(decorate_name(namespace))
          end
        end

        if namespace.base?(:decorate_name)
          Named.snake_case_name(decorate_name(namespace))
        else
          Named.snake_case_name(namespace.name_words)
        end
      end
    end
  end
end
