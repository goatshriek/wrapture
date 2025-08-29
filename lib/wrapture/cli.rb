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

require 'thor'

module Wrapture
  # CLI tools for Wrapture invocations.
  module Cli
    # The wrapture command line interface.
    class Command < Thor
      # The exit code for the wrapture command is non-zero if an error is
      # encountered.
      def self.exit_on_failure?
        true
      end

      desc 'wrap <options>', 'generate wrappers for the given specs'
      option :class, aliases: 'c',
                     desc: 'file with a class spec',
                     repeatable: true
      option :from, desc: 'language to start wrapping from'
      option :function, aliases: 'f',
                        desc: 'file with a function spec',
                        repeatable: true
      option :enum, aliases: 'e',
                    desc: 'file with a enum spec',
                    repeatable: true
      option :path, aliases: 'p',
                    desc: 'sequence of wrappers to call',
                    repeatable: true
      option :scope, aliases: 's',
                     desc: 'file with a scope spec',
                     repeatable: true
      option :to, desc: 'language to generate wrappers for'
      # The wrap cli command.
      def wrap
        if options[:path] && (options[:to] || options[:from])
          raise Thor::Error, '--path (-p) cannot be used with --from or --to'
        end

        puts 'wrap called!'
        puts "scope: #{options[:scope]}"
      end
    end
  end
end
