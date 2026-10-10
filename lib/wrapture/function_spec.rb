# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2026 Joel E. Anderson
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

require 'wrapture/named'

module Wrapture
  # A description of a function to be generated, including details about the
  # underlying implementation.
  class FunctionSpec
    include Named

    # Set whether this function is a constructor.
    attr_writer :constructor

    # Set whether this function is a destructor.
    attr_writer :destructor

    # Documentation for the function.
    attr_writer :doc

    # Initializers for the function.
    attr_reader :initializers

    # The words that make up the function name.
    attr_reader :name_words

    # A list of the ParamSpecs this function accepts.
    attr_accessor :params

    # Documentation for the function return.
    attr_accessor :return_doc

    # True if the return is overloaded for this function.
    attr_writer :return_overloaded

    # A TypeSpec describing the return type of this function.
    attr_accessor :return_type

    # A map of source language functions this spec wraps.
    attr_accessor :source

    # Set whether this function is static.
    attr_writer :static

    # Set whether this function is virtual.
    attr_writer :virtual

    # Creates a new FunctionSpec from +hash+.
    #
    # The hash must have a +:name+ key with the name of the function, either as
    # a +String+ or an +Array+ of name words. The remaining keys are optional.
    #
    # The +:params+ key is an +Array+ of parameters for the function. Each entry
    # in this array must be a +Hash+ used to create a +ParamSpec+. Only one
    # parameter may be named +...+ and it must be last in the +Array+.
    #
    # The +:source+ key contains a +Hash+ that describes the implementation
    # of the function. This may either contain a +:c+ key containing a +Hash+
    # used to create a +CFunction+, or an +:alias+ key with the name of another
    # function (either a +String+ or an +Array+ of words) that this one is
    # equivalent to.
    #
    # The +:return+ key has a Hash with a +:type+ key with the name of the
    # type the function returns, and/or a +:doc+ key with documentation on the
    # return value itself. If neither of these is needed, then the key may
    # be omitted.
    #
    # The +:type+ key of the return spec may also be set to 'self_reference'
    # which will have the function return a reference to the instance it was
    # called on. Of course, this cannot be used from a function that is not a
    # class method.
    #
    # The +initializers+ key  contains hashes each with a 'name' and
    # 'values' key designating the member to be initialized and the
    # expression(s) to use for initialization, respectively. Optionally, the
    # 'name' key may be omitted if the function is a constructor and a key named
    # 'delegate' is present and set to true. This will use the name of the class
    # the constructor belongs to as the name.
    #
    # Other optional keys (symbols with this name):
    # constructor:: true if this function is a constructor
    # destructor:: true if this function is a destructor
    # doc:: a string containing the documentation for this function
    # static:: true if this is a static function
    # virtual:: true if this is a virtual function
    def self.from_hash(hash)
      validate_hash(hash)

      func_spec = new(hash[:name])
      func_spec.doc = Comment.new(hash.fetch(:doc, ''))
      func_spec.constructor = Wrapture.normalize_boolean(hash, :constructor)
      func_spec.destructor = Wrapture.normalize_boolean(hash, :destructor)
      func_spec.static = Wrapture.normalize_boolean(hash, :static)
      func_spec.virtual = Wrapture.normalize_boolean(hash, :virtual)

      if hash.key?(:initializers)
        func_spec.initializers.concat(hash[:initializers])
      end

      func_spec.params.concat(params) if hash.key?(:params)

      if hash.key?(:return)
        func_spec.return_overloaded = Wrapture.normalize_boolean(hash[:return],
                                                                 :overloaded)

        type_val = hash[:return].fetch(:type, 'void')
        func_spec.return_type = if type_val.is_a?(Hash)
                                  TypeSpec.from_hash(type_val)
                                else
                                  TypeSpec.new(type_val)
                                end

        if hash[:return].key?(:doc)
          Comment.validate_doc(hash[:return][:doc])
          func_spec.return_doc = Comment.new(hash[:return][:doc])
        end
      end

      set_source_from_hash(func_spec, hash.fetch(:source, {}))

      func_spec
    end

    # Checks +hash+ to see if it is a valid class hash. Raises an exception if
    # it is not.
    def self.validate_hash(hash)
      unless Wrapture.supports_version?(hash.fetch(:version, Wrapture::VERSION))
        raise UnsupportedSpecVersion
      end

      if hash.key?(:initializers) && hash[:initializers].any? do |it|
        !it.key?(:name) && !it[:delegate]
      end
        msg = 'initializers must either have a name or be delegating ' \
              'constructors (have delegate set to true)'
        raise MissingSpecKey, msg
      end

      if func_spec.constructor? && hash.dig(:source, :c, :return, :type).nil?
        raise InvalidConstructor, 'a constructor did not have a return type'
      end

      if hash.key?(:params)
        params = ParamSpec.from_hashes(hash[:params])
        if params.length == 1 && params.last.variadic?
          raise InvalidSpecKey, 'the only parameter may not be variadic'
        end
      end
    end

    # Sets the members of the +source+ property of the +FunctionSpec+ +spec+
    # based on the contents of +hash+.
    private_class_method def self.set_source_from_hash(spec, hash)
      if hash.key?(:alias)
        spec[:alias] = hash[:alias]
      elsif hash.key?(:c)
        spec[:c] = CSource::CFunction.from_hash(hash[:c])
      end
    end

    # A new function must have a +name+, provided either as a +String+ or an
    # +Enumerable+ of objects that are converted to words via their +to_s+
    # method.
    def initialize(name)
      @name_words = Wrapture.normalize_name_words(name)
      @doc = nil
      @source = {}
      @params = []
      @return_doc = nil
      @return_overloaded = false
      @return_type = TypeSpec.new('void')
      @constructor = false
      @destructor = false
      @static = false
      @virtual = false
      @initializers = []
    end

    # Get the source function for the given language. This is equivalent to
    # +source[lang]+.
    def [](lang)
      @source[lang]
    end

    # Set the source function for the given language. This is equivalent to
    # +source[lang]=+.
    def []=(lang, source_function)
      @source[lang] = source_function
    end

    # True if the function is a constructor, false otherwise.
    def constructor?
      @constructor
    end

    # True if the function is a destructor, false otherwise.
    def destructor?
      @destructor
    end

    # A Comment holding the function documentation.
    def doc
      comment = Comment.new
      comment << @doc unless @doc.nil?

      @params
        .reject { |param| param.doc.empty? }
        .each { |param| comment << "\n\n" << param.doc.text }

      comment << "\n\n@return " << @return_doc.text unless @return_doc.nil?

      comment
    end

    # The parameters that are optional (have default values) for this function.
    def optional_params
      @params.select(&:default_value?)
    end

    # True if this function has parameters.
    def params?
      !@params.empty?
    end

    # The parameters that are required (no default values) for this function.
    def required_params
      @params.reject(&:default_value?)
    end

    # True if the return type of this function is overloaded.
    def return_overloaded?
      @return_overloaded
    end

    # True if the function is static.
    def static?
      @static
    end

    # A string representation of the function.
    def to_s
      upper_camel_case_name
    end

    # True if the function is variadic.
    def variadic?
      @params.last&.variadic?
    end

    # True if the function is virtual.
    def virtual?
      @virtual
    end

    # True if the function has a void return type.
    def void_return?
      @return_type.void?
    end
  end
end
