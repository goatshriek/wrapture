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

      # Don't allow options that aren't recognized.
      check_unknown_options!

      # Support help for all commands.
      class_option :help, aliases: 'h',
                          desc: 'output command help',
                          type: :boolean

      # Support version for all commands.
      class_option :version, aliases: 'v',
                             desc: 'output command version',
                             type: :boolean

      desc 'wrap <options> [SPEC] ...', 'generate wrappers for the given specs'
      long_desc <<-LONGDESC
        The wrap command wraps all of the given specs in following the provided
        wrapping paths.

        Specs are provided as paths to YAML files containing the specs. Specs
        are assumed to be scope specs, and will all be combined into the same
        scope during loading.

        The --from and --to options allow the starting and ending languages to
        be manually specified. If either (or both) option is given, then only
        paths with the specified starting language (--from) and ending language
        (--to) are used. If neither option is given, then all paths in Wrapture
        are attempted.

        The --path option allows for complete control over the wrapping paths.
        It allows precise control over the paths used, and allows invocations
        not supported by the simpler --from and --to options. A path is given
        as a comma-separated list of languages, defining a chain of wrappers
        to follow. For example, "c,cpp" will invoke the CToCpp wrapper, and
        "c,python,java" will invoke the CToPython wrapper followed by the
        PythonToJava wrapper. The --path option can be given multiple times to
        generate several different wrapping paths in a single invocation.
      LONGDESC
      # TODO: allow more fine-grained loading of specs
      # option :class, aliases: 'c',
      #                desc: 'file with a class spec',
      #                repeatable: true
      # TODO: not implemented yet
      # option :format, desc: 'output format (diff, files, zip)',
      #                 default: 'file'
      option :from, desc: 'language to start wrapping from'
      # TODO: allow more fine-grained loading of specs
      # option :function, aliases: 'f',
      #                   desc: 'file with a function spec',
      #                   repeatable: true
      # option :enum, aliases: 'e',
      #               desc: 'file with a enum spec',
      #               repeatable: true
      # TODO: add this in when it is implemented
      # option :jobs, aliases: 'j',
      #               desc: 'number of parallel jobs to run'
      # TODO: add this in when it is implemented
      # option :log, aliases: 'l',
      #              desc: 'file to write log output to'
      # output may change to be a filename when different formats are supported
      option :namespace, aliases: 'n',
                         desc: 'file with a namespace spec',
                         repeatable: true
      option :output, aliases: 'o',
                      desc: 'output directory'
      option :path, aliases: 'p',
                    desc: 'sequence of wrappers to call',
                    repeatable: true
      option :to, desc: 'language to generate wrappers for'
      exclusive :path, :to
      exclusive :path, :from
      # The wrap cli command.
      def wrap(*specs)
        return help(:wrap) if options[:help]

        if options[:version]
          puts "Wrapture #{Wrapture::VERSION}"
          return
        end

        config = Config::WrapConfig.new

        config.paths = if options[:path]
                         options[:path].map { |it| Path.new(it) }
                       else
                         Wrapture.paths(from: options[:from]&.to_sym,
                                        to: options[:to]&.to_sym)
                       end

        options[:namespaces]&.each do |it|
          config.namespaces << PlainNamespace.from_yaml_file(it)
        end

        specs.each do |it|
          config.namespaces << PlainNamespace.from_yaml_file(it)
        end

        config.output = options[:output] if options[:output]

        Wrapture.wrap(config)
      end
    end
  end
end
