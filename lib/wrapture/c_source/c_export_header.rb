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

require 'wrapture/c_source/c_source_file'

module Wrapture
  module CSource
    # A header file that defines export macros for public functions.
    #
    # Exposing functions in C libraries differs between build toolchains. One
    # of the most common examples is the difference between the Microsoft
    # compiler, which uses <tt>__declspec(dllexport)</tt> to designate a
    # function as exported in a DLL, and GCC which uses
    # <tt>__attribute__ ((visibility ("default")))</tt> to mark a function as
    # visible in the resulting shared library.
    #
    # An export header defines one or more macros that can be used in library
    # headers, which expand to the appropriate visibility incantation based on
    # the toolchain they are used from.
    #
    # This is a separate source file class because some build systems, such as
    # +Build::CmakeBuild+, can generate these headers on their own. In those
    # cases, a source file set's export header can be filtered out, and the
    # build system can generate its own instead.
    class CExportHeader < CSourceFile
      # The base name used to derive the export macro names.
      attr_reader :base_name

      # A base name to use for a +Named+ +spec+.
      def self.base_name(spec)
        spec.screaming_snake_case_name
      end

      # An export header name derived from a +Named+ +spec+.
      def self.export_header_name(spec)
        if spec.name_words.empty?
          'export.h'
        else
          "#{spec.snake_case_name}_export.h"
        end
      end

      # A fully-defined export header for a +Named+ +spec+.
      #
      # The export macro will be +CExportHeader.base_name+ with "_EXPORT"
      # added to the end. This macro will be defined differently depending on
      # if a similar symbol with a suffix of "_EXPORTING" is defined, which will
      # signify that the library is being built instead of used. This is
      # necessary in order to properly support the dllimport/dllexport semantics
      # used by the Microsoft C compiler: see
      # {the Microsoft Learn article}[https://learn.microsoft.com/en-us/cpp/build/importing-into-an-application-using-declspec-dllimport]
      # for more information.
      def self.from_spec(spec, path: nil)
        header_name = if path.nil?
                        export_header_name(spec)
                      else
                        path
                      end
        base_name = base_name(spec)
        guard = header_name.upcase.gsub('.', '_')
        header = new(header_name, base_name)

        content = <<~HEADER_CONTENT
          #ifndef #{guard}
          #define #{guard}

          /**
           * @file #{header_name}
           * @brief An export header for #{base_name}.
           * This header defines the macro that is used in public headers that
           * make their contents available for external use.
           */

          /**
           * @def #{base_name}_EXPORT
           * An attribute that designates that a class or function should be
           * available to users of this library.
           */

          #ifdef _WIN32
          #  ifdef #{base_name}_EXPORTING
          #    define #{base_name}_EXPORT __declspec(dllexport)
          #  else
          #    define #{base_name}_EXPORT __declspec(dllimport)
          #  endif
          #else
          #  define #{base_name}_EXPORT __attribute__((visibility("default")))
          #endif

          #endif /* #{guard} */
        HEADER_CONTENT

        header.puts(content)

        header
      end

      # An export header has a +path+, as well as a +base_name+ that is used
      # to derive the name of the export macros defined in the header.
      def initialize(path, base_name)
        super(path)
        @base_name = base_name
      end
    end
  end
end
