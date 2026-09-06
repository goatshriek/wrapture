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

    # The owner of this function. This may be an empty scope if no owner was
    # defined for this function.
    attr_accessor :owner

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

    # Creates a new FunctionSpec from hash +spec+.
    #
    # The hash must have a 'name' key with the name of the function, either as
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
    def self.from_hash(spec)
      unless Wrapture.supports_version?(spec.fetch(:version, Wrapture::VERSION))
        raise UnsupportedSpecVersion
      end

      if spec.key?(:initializers) && spec[:initializers].any? do |it|
        !it.key?(:name) && !it[:delegate]
      end
        msg = 'initializers must either have a name or be delegating ' \
              'constructors (have delegate set to true)'
        raise MissingSpecKey, msg
      end

      Comment.validate_doc(spec[:doc]) if spec.key?(:doc)

      name = Wrapture.normalize_name(spec, :name)

      func_spec = new(name)
      func_spec.doc = Comment.new(spec[:doc]) if spec.key?(:doc)
      func_spec.constructor = Wrapture.normalize_boolean(spec, :constructor)
      func_spec.destructor = Wrapture.normalize_boolean(spec, :destructor)
      func_spec.static = Wrapture.normalize_boolean(spec, :static)
      func_spec.virtual = Wrapture.normalize_boolean(spec, :virtual)

      if spec.key?(:initializers)
        func_spec.initializers.concat(spec[:initializers])
      end

      if spec.key?(:params)
        param_specs = ParamSpec.normalize_param_list(spec[:params])
        func_spec.params.concat(ParamSpec.new_list(param_specs))
      end

      if spec.key?(:return)
        func_spec.return_overloaded = Wrapture.normalize_boolean(spec[:return],
                                                                 :overloaded)
        if spec[:return].key?(:type)
          func_spec.return_type = TypeSpec.new(spec[:return][:type])
        end

        if spec[:return].key?(:doc)
          Comment.validate_doc(spec[:return][:doc])
          func_spec.return_doc = Comment.new(spec[:return][:doc])
        end
      end

      set_source_from_hash(func_spec, spec[:source]) if spec.key?(:source)

      func_spec
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
      @owner = Scope.new
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

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      includes = @return_type.includes
      @params.each { |param| includes.concat(param.includes) }
      includes.concat(@return_type.includes)
      includes.uniq
    end

    # True if this function can be defined, false if not.
    #
    # If +lang+ is given, then the result is true only if this function is
    # definable for the given language. If not, the result is true if the
    # function is definable for any language.
    #
    # In the long term, this should probably be renamed to something like
    # "wrappable?" and added to ClassSpec and/or Scope.
    def definable?(lang: nil)
      # TODO: remove, replace with check of source for lang key
      if lang.nil?
        !@source.empty?
      else
        @source.key?(lang)
      end
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @source[:c].includes
      includes.concat(@return_type.includes)
      @params.each { |param| includes.concat(param.includes) }
      includes.concat(@return_type.includes)
      includes << 'stdarg.h' if variadic?
      includes.uniq
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

    # An array of libraries required for this function call.
    def libraries
      # TODO: there shouldn't be C-specific code here
      if @source.empty? || !@source.key?(:c)
        []
      else
        @source[:c].libraries
      end
    end

    # The parameters that are optional (have default values) for this function.
    def optional_params
      @params.select(&:default_value?)
    end

    # True if this function is overloaded in it's owning scope.
    def overloaded?
      case @owner
      when ClassSpec
        @owner.functions.count do |f|
          f.name_words == name_words &&
            f.constructor? == constructor? &&
            f.destructor? == destructor?
        end > 1
      else false
      end
    end

    # An array of the names of the function params.
    def param_names
      @params.map(&:name)
    end

    # True if this function has parameters.
    def params?
      !@params.empty?
    end

    # The parameters that are required (no default values) for this function.
    def required_params
      @params.reject(&:default_value?)
    end

    # A resolved type, given a TypeSpec +type+. Resolved types will not have any
    # placeholders like +equivalent_struct+, which will be resolved to their
    # effective type.
    #
    # TODO: This C-specific code should be removed from FunctionSpec
    def resolve_type(type_spec)
      if type_spec.equivalent_struct?
        TypeSpec.new("struct #{@owner[:c].name}")
      elsif type_spec.equivalent_pointer?
        TypeSpec.new("struct #{@owner[:c].name} *")
      elsif type_spec.self_reference?
        TypeSpec.new("#{@owner.name}&")
      else
        type_spec
      end
    end

    # The resolved type of the return type.
    def resolved_return
      @return_type.resolve(self)
    end

    # Calls return_expression on the return type of this function. +func_name+
    # is passed to return_expression if provided.
    def return_expression(func_name: name)
      if @constructor || @destructor
        signature(func_name: func_name)
      else
        resolved_return.return_expression(self, func_name: func_name)
      end
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
      @return_type.name == 'void'
    end
  end
end
