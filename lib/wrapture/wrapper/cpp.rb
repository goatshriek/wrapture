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
  module Wrapper
    # Utilities for wrappers that use C++ as either a from or to language.
    module Cpp
      # The fully qualified namespace for given context.
      def self.context_namespace(context)
        base_name = case context.root
                    when Namespace
                      namespace_name(context.root)
                    else
                      ''
                    end

        if context.parent?
          base_name.prepend('::').prepend(context_namespace(context.parent))
        else
          base_name
        end
      end

      # Makes a decorated version of the given name so that it is unique among
      # other names based on the C++ language. This is done by prepending "cpp"
      # to the name: for example "MyLib" will become "CppMyLib".
      def self.decorate_name_words(name_words)
        ['cpp'] + name_words
      end

      # The decorated name words for Named instance +named+.
      def self.decorated_name(named)
        decorate_name_words(named.name_words)
      end

      # The symbol to use for header guard checks.
      def self.header_guard(spec)
        "#{spec.screaming_snake_case_name}_HPP"
      end

      # The name of the header file for Named entity +named+.
      def self.header_name(named)
        case named
        when ClassSpec, EnumSpec
          "#{named.upper_camel_case_name}.hpp"
        else
          "#{named.snake_case_name}.hpp"
        end
      end

      # The effective C++ name for +namespace+.
      def self.namespace_name(namespace)
        if namespace.source.key?(:cpp)
          if namespace.source[:cpp].key?(:name)
            return namespace.source[:cpp][:name]
          elsif namespace.source[:cpp].key?(:decorate_name) &&
                namespace.source[:cpp][:decorate_name]
            return Named.snake_case_name(decorated_name(namespace))
          end
        end

        if namespace.base?(:decorate_name)
          Named.snake_case_name(decorated_name(namespace))
        else
          Named.snake_case_name(namespace.name_words)
        end
      end
    end
  end
end
