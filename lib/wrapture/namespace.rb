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

require 'wrapture/sourced'

module Wrapture
  # A Namespace is a logical element that contains other elements within it. The
  # actual contents of a Namespace are determined by creating a Context with a
  # Namespace as its root.
  class Namespace
    include Named
    include Sourced

    # The pieces of the namespace name.
    attr_reader :name_words

    # A Hash of language-specific wrapping details.
    #
    # Details for the C++ language are stored in the +:cpp+ key. This may have
    # the following keys (as symbols):
    # name:: A String of the namespace name. This will override the namespace
    # name automatically generated from +name_words+.
    attr_reader :source

    # Creates a new Namespace from +hash+.
    #
    # +hash+ must have a +:name+ key with either a String or an array of
    # strings.
    #
    # +hash+ may have a +:source+ key, which is used to populate the +source+
    # hash of the resulting namespace.
    def self.from_hash(hash)
      unless hash.key?(:name)
        raise MissingSpecKey, 'namespace hashes must have a :name key'
      end

      if hash.key?(:source)
        unless hash[:source].is_a?(Hash)
          raise InvalidSpec, 'the source key must contain a hash'
        end

        hash[:source].each_key.each do |it|
          unless hash[:source][it].is_a?(Hash)
            raise InvalidSpec, "source key #{it} must contain a hash"
          end

          if hash[:source][it].key?(:name) &&
             !hash[:source][it][:name].is_a?(String)
            raise InvalidSpec, "source key #{it} name must be a string"
          end
        end
      end

      ns = new(hash[:name])

      if hash.key?(:source)
        hash[:source].each_key do |it|
          ns.source[it] = hash[:source][it]
        end
      end

      ns
    end

    # Creates a new Namespace from the YAML loaded from +filename+.
    def self.from_yaml_file(filename)
      # simplify this to just safe_load_file after Ruby 2.7 is dropped
      ns_hash = if YAML.respond_to?('safe_load_file')
                  YAML.safe_load_file(filename, symbolize_names: true)
                else
                  File.open(filename, 'r:bom|utf-8') do |f|
                    YAML.safe_load(f, filename: filename,
                                      symbolize_names: true)
                  end
                end

      from_hash(ns_hash)
    end

    # A plain namespace is created with a name and empty contents.
    def initialize(name)
      @name_words = if name.is_a?(String)
                      Named.words_from_name(name)
                    else
                      name
                    end
      @source = {}
    end
  end
end
