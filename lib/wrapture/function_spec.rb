# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2025 Joel E. Anderson
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

    # Creates a new FunctionSpec from a hash +spec+.
    def self.from_hash(spec)
      if spec&.key?(:version) && !Wrapture.supports_version?(spec[:version])
        raise UnsupportedSpecVersion
      end

      if spec.key?(:initializers) && spec[:initializers].any? do |i|
        !i.key?(:name) && !i[:delegate]
      end
        msg = 'initializers must either have a name or be delegating ' \
              'constructors (have delegate set to true)'
        raise MissingSpecKey, msg
      end

      Comment.validate_doc(spec[:doc]) if spec.key?(:doc)

      name = Wrapture.normalize_name(spec, :name)

      func_spec = new(name)
      func_spec.doc = Comment.new(spec[:doc]) if spec.key?(:doc)
      func_spec.params = ParamSpec.normalize_param_list(spec[:params])
      func_spec.constructor = Wrapture.normalize_boolean(spec, :constructor)
      func_spec.destructor = Wrapture.normalize_boolean(spec, :destructor)
      func_spec.static = Wrapture.normalize_boolean(spec, :static)
      func_spec.virtual = Wrapture.normalize_boolean(spec, :virtual)

      func_spec.initializers = spec[:initializers] if spec.key?(:initializers)

      if spec.key?(:return)
        func_spec.return_overloaded = Wrapture.normalize_boolean(spec[:return],
                                                                 :overloaded)
        func_spec.return_type = TypeSpec.new(spec[:return][:type])
        if spec[:return].key?(:doc)
          Comment.validate_doc(spec[:return][:doc])
          func_spec.return_doc = Comment.new(spec[:return][:doc])
        end
      end

      if spec.key?(:wrapped) && spec[:wrapped].key?(:c)
        func_spec.wrapped[:c] = CSource::CFunction.from_hash(spec[:wrapped][:c])
      end

      func_spec
    end

    # Returns a copy of the return type specification +spec+.
    def self.normalize_return_hash(spec)
      if spec.nil?
        { type: 'void', includes: [] }
      else
        normalized = Marshal.load(Marshal.dump(spec))
        Comment.validate_doc(spec[:doc]) if spec.key?(:doc)
        normalized[:type] ||= 'void'
        normalized[:includes] = Wrapture.normalize_array(spec[:includes])
        normalized[:libraries] = Wrapture.normalize_array(spec[:libraries])
        Wrapture.normalize_boolean!(spec, :overloaded)
        normalized
      end
    end

    # Normalizes the hash specification of a function in +spec+ in place.
    # Normalization will check for things like invalid keys, duplicate entries
    # in include lists, and will set missing keys to their default values
    # (for example, an empty list if no includes are given).
    def self.normalize_spec_hash!(spec)
      Comment.validate_doc(spec[:doc]) if spec.key?(:doc)

      spec[:version] = Wrapture.spec_version(spec)
      Wrapture.normalize_boolean!(spec, :static)
      Wrapture.normalize_boolean!(spec, :virtual)
      spec[:params] = ParamSpec.normalize_param_list(spec[:params])
      spec[:return] = normalize_return_hash(spec[:return])
      spec[:name] = Wrapture.normalize_name(spec, :name)

      spec[:initializers] = [] unless spec.key?(:initializers)
      if spec[:initializers].any? { |i| !i.key?(:name) && !i[:delegate] }
        msg = 'initializers must either have a name or be delegating ' \
              'constructors (have delegate set to true)'
        raise MissingSpecKey, msg
      end

      spec
    end

    # Creates a function spec based on the provided function spec.
    #
    # The hash must have a 'name' key with the name of the function in
    # CamelCase, unless it is a constructor or destructor in which case it
    # will be automatically named according to its class.
    #
    # The function may also specify what the underlying implementation will be
    # via one of the following keys. If neither is specified, then the function
    # will not be considered definable, but may still be declared. Both may not
    # be specified in the same function.
    # wrapped-code:: a hash describing raw C code to be wrapped
    # wrapped-function:: a hash describing a C function to be wrapped
    #
    # The wrapped-code hash must have a 'lines' key with a list of lines of code
    # that will replace the function. It may optionally include an 'includes'
    # key with a list of includes that are needed for this function to compile,
    # and/or a 'return' key with a type description of the return value
    # variable. If this function has a return value, it must be stored in a
    # variable named 'return_val' at the end of this code. The return statement
    # itself will be auto-generated, and should _not_ be included in the code
    # lines provided.
    #
    # The wrapped-function hash must have a 'name' key with the name of the
    # function, and a 'params' key with a list of parameters (each a hash with a
    # 'name' and 'type' key). Optionally, it may also include an 'includes' key
    # with a list of includes that are needed for this function to compile,
    # and/or a 'return' key with a type description of the wrapped function's
    # return value.
    #
    # The following keys are optional:
    # params:: a list of parameter specifications
    # doc:: a string containing the documentation for this function
    # return:: a specification of the return value for this function
    # static:: set to true if this is a static function
    # virtual:: set to true if this is a virtual function
    # initializers:: a list of member initializers
    #
    # Each parameter specification must have a 'name' key with the name of the
    # parameter and a 'type' key with its type. The type key may be ommitted
    # if the name of the parameter is '...' in which case the generated function
    # will be made variadic. It may optionally have an 'includes' key with
    # includes that are required (for example to support the type) and/or a
    # 'doc' key with documentation of the parameter.
    #
    # Only one parameter named '...' is allowed in a specification. If more than
    # one is provided, then only the first encountered will be used. This
    # parameter should also be last - if it is not, it will be moved to the end
    # of the parameter list during normalization.
    #
    # The return specification may have either a 'type' key with the name of the
    # type the function returns, and/or a 'doc' key with documentation on the
    # return value itself. If neither of these is needed, then the return
    # specification may simply be omitted.
    #
    # The 'type' key of the return spec may also be set to 'self_reference'
    # which will have the function return a reference to the instance it was
    # called on. Of course, this cannot be used from a function that is not a
    # class method.
    #
    # The optional initializer list contains hashes each with a 'name' and
    # 'values' key designating the member to be initialized and the
    # expression(s) to use for initialization, respectively. Optionally, the
    # 'name' key may be omitted if the function is a constructor and a key named
    # 'delegate' is present and set to true. This will use the name of the class
    # the constructor belongs to as the name.
    def initialize(name_words)
      @name_words = Wrapture.normalize_name_words(name_words)
      @doc = nil
      @owner = Scope.new
      @wrapped = {}
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

    # Set whether this function is a constructor.
    attr_writer :constructor

    # Set whether this function is a destructor.
    attr_writer :destructor

    # Documentation for the function.
    attr_writer :doc

    # Initializers for the function.
    attr_accessor :initializers

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
    attr_accessor :return_overloaded

    # A TypeSpec describing the return type of this function.
    attr_accessor :return_type

    # Set whether this function is static.
    attr_writer :static

    # Set whether this function is virtual.
    attr_writer :virtual

    # A map of language-specific functions this spec wraps.
    attr_accessor :wrapped

    # Get the wrapped function for the given language. This is equivalent to
    # +wrapped[lang]+.
    def [](lang)
      @wrapped[lang]
    end

    # Set the wrapped function for the given language. This is equivalent to
    # +wrapped[lang]+.
    def []=(lang, wrapped_function)
      @wrapped[lang] = wrapped_function
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
      if lang.nil?
        @wrapped.length.positive?
      else
        @wrapped.key?(lang)
      end
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @wrapped[:c].includes
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
      comment = String.new
      comment << @doc unless @doc.nil?

      @params
        .reject { |param| param.doc.empty? }
        .each { |param| comment << "\n\n" << param.doc.text }

      comment << "\n\n@return " << @return_doc.text unless @return_doc.nil?

      Comment.new(comment)
    end

    # An array of libraries required for this function call.
    def libraries
      if @wrapped.empty?
        []
      else
        @wrapped[:c].libraries
      end
    end

    # The parameters that are optional (have default values) for this function.
    def optional_params
      @params.select(&:default_value?)
    end

    # True if this function is overloaded in it's owning scope.
    def overloaded?
      case @owner
      when Scope
        false
      when ClassSpec
        @owner.functions.count do |f|
          f.name_words == name_words &&
            f.constructor? == constructor? &&
            f.destructor? == destructor?
        end > 1
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
    def resolve_type(type_spec)
      if type_spec.equivalent_struct?
        TypeSpec.new("struct #{@owner.struct_name}")
      elsif type_spec.equivalent_pointer?
        TypeSpec.new("struct #{@owner.struct_name} *")
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

    # True if the function is static.
    def static?
      @static
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
