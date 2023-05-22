# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2023 Joel E. Anderson
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

    # Returns a copy of the return type specification +spec+.
    def self.normalize_return_hash(spec)
      if spec.nil?
        { 'type' => 'void', 'includes' => [] }
      else
        normalized = Marshal.load(Marshal.dump(spec))
        Comment.validate_doc(spec['doc']) if spec.key?('doc')
        normalized['type'] ||= 'void'
        normalized['includes'] = Wrapture.normalize_array(spec['includes'])
        Wrapture.normalize_boolean!(spec, 'overloaded')
        normalized
      end
    end

    # Normalizes a hash specification of a function. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and will
    # set missing keys to their default values (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      normalize_spec_hash!(Marshal.load(Marshal.dump(spec)))
    end

    # Normalizes the hash specification of a function in +spec+ in place.
    # Normalization will check for things like invalid keys, duplicate entries
    # in include lists, and will set missing keys to their default values
    # (for example, an empty list if no includes are given).
    def self.normalize_spec_hash!(spec)
      Comment.validate_doc(spec['doc']) if spec.key?('doc')

      spec['version'] = Wrapture.spec_version(spec)
      Wrapture.normalize_boolean!(spec, 'static')
      Wrapture.normalize_boolean!(spec, 'virtual')
      spec['params'] = ParamSpec.normalize_param_list(spec['params'])
      spec['return'] = normalize_return_hash(spec['return'])

      spec['initializers'] = [] unless spec.key?('initializers')
      if spec['initializers'].any? { |i| !i.key?('name') && !i['delegate'] }
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
    # The 'type' key of the return spec may also be set to 'self-reference'
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
    def initialize(spec, owner = Scope.new, constructor: false,
                   destructor: false)
      @owner = owner
      @spec = FunctionSpec.normalize_spec_hash(spec)
      @wrapped = if @spec.key?('wrapped-function')
                   WrappedFunctionSpec.new(@spec['wrapped-function'])
                 elsif @spec.key?('wrapped-code')
                   WrappedCodeSpec.new(@spec['wrapped-code'])
                 end
      @params = ParamSpec.new_list(@spec['params'])
      @return_type = TypeSpec.new(@spec['return']['type'])
      @constructor = constructor
      @destructor = destructor
    end

    # The owner of this function, if there is one.
    attr_reader :owner

    # A list of the ParamSpecs this function accepts.
    attr_reader :params

    # A TypeSpec describing the return type of this function.
    attr_reader :return_type

    # A WrappedFunctionSpec or WrappedCodeSpec this .
    attr_reader :wrapped

    # True if the return value of the wrapped call is saved.
    def capture_return?
      !@constructor && (@wrapped.use_return? || returns_return_val?)
    end

    # True if the function is a constructor, false otherwise.
    def constructor?
      @constructor
    end

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      includes = @spec['return']['includes'].dup
      @params.each { |param| includes.concat(param.includes) }
      includes.concat(@return_type.includes)
      includes.uniq
    end

    # True if this function can be defined, false if not.
    def definable?
      definable!
    rescue UndefinableSpec
      false
    end

    # Raises an exception if this function cannot be defined as is. Returns
    # true otherwise.
    def definable!
      if @wrapped.nil?
        raise UndefinableSpec, 'no wrapped function or code was specified'
      end

      true
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @wrapped.includes
      includes.concat(@spec['return']['includes'])
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
      comment << @spec['doc'] if @spec.key?('doc')

      @params
        .reject { |param| param.doc.empty? }
        .each { |param| comment << "\n\n" << param.doc.text }

      if @spec['return'].key?('doc')
        comment << "\n\n@return " << @spec['return']['doc']
      end

      Comment.new(comment)
    end

    # A list of initializer specs.
    def initializers
      @spec['initializers']
    end

    # An array of libraries required for this function call.
    def libraries
      @wrapped.libraries
    end

    # The name of the function.
    def name
      @spec['name']
    end

    # A string with the parameter list for this function.
    def param_list
      ParamSpec.signature(@params, self)
    end

    # A resolved type, given a TypeSpec +type+. Resolved types will not have any
    # keywords like +equivalent-struct+, which will be resolved to their
    # effective type.
    def resolve_type(type)
      if type.equivalent_struct?
        TypeSpec.new("struct #{@owner.struct_name}")
      elsif type.equivalent_pointer?
        TypeSpec.new("struct #{@owner.struct_name} *")
      elsif type.self_reference?
        TypeSpec.new("#{@owner.name}&")
      else
        type
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
      @spec['return']['overloaded']
    end

    # True if the function returns the result of the wrapped function call
    # directly without any after actions.
    def returns_call_directly?
      !@constructor &&
        !@destructor &&
        !%w[void self-reference].include?(@spec['return']['type']) &&
        !@wrapped.error_check?
    end

    # The signature of the function. +func_name+ can be used to override the
    # function name if needed, for example if a class name qualifier is needed.
    def signature(func_name: name)
      "#{func_name}( #{param_list} )"
    end

    # True if the function is static.
    def static?
      @spec['static']
    end

    # True if the function is variadic.
    def variadic?
      @params.last&.variadic?
    end

    # True if the function is virtual.
    def virtual?
      @spec['virtual']
    end

    # True if the function has a void return type.
    def void_return?
      @return_type.name == 'void'
    end

    private

    # True if the function returns the return_val variable.
    def returns_return_val?
      !@return_type.self_reference? &&
        @spec['return']['type'] != 'void' &&
        !returns_call_directly?
    end
  end
end
