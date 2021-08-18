# SPDX-License-Identifier: Apache-2.0

# frozen_string_literal: true

#--
# Copyright 2019-2020 Joel E. Anderson
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
  # A description of a function to be generated, including details about the
  # underlying implementation.
  class FunctionSpec
    # Returns a copy of the return type specification +spec+.
    def self.normalize_return_hash(spec)
      if spec.nil?
        { 'type' => 'void', 'includes' => [] }
      else
        normalized = Marshal.load(Marshal.dump(spec))
        Comment.validate_doc(spec['doc']) if spec.key?('doc')
        normalized['type'] ||= 'void'
        normalized['includes'] = Wrapture.normalize_includes(spec['includes'])
        normalized
      end
    end

    # Normalizes a hash specification of a function. Normalization will check
    # for things like invalid keys, duplicate entries in include lists, and will
    # set missing keys to their default values (for example, an empty list if no
    # includes are given).
    def self.normalize_spec_hash(spec)
      Comment.validate_doc(spec['doc']) if spec.key?('doc')

      normalized = spec.dup

      normalized['version'] = Wrapture.spec_version(spec)
      normalized['virtual'] = Wrapture.normalize_boolean(spec, 'virtual')
      normalized['params'] = ParamSpec.normalize_param_list(spec['params'])
      normalized['return'] = normalize_return_hash(spec['return'])

      overload = Wrapture.normalize_boolean(normalized['return'], 'overloaded')
      normalized['return']['overloaded'] = overload

      normalized
    end

    # Creates a function spec based on the provided function spec.
    #
    # The hash must have the following key:
    # name:: the name of the function
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

    # A TypeSpec describing the return type of this function.
    attr_reader :return_type

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

    # True if this function can be defined.
    def definable?
      definable_check
    rescue UndefinableSpec
      false
    end

    # Gives the definition of the function in a block, line by line.
    def definition
      definable_check

      yield "#{return_expression(func_name: qualified_name)} {"

      locals { |declaration| yield "  #{declaration}" }

      yield "  va_start( variadic_args, #{@params[-2].name} );" if variadic?
      yield ''

      if @wrapped.is_a?(WrappedFunctionSpec)
        yield "  #{wrapped_call_expression};"
      else
        @wrapped.lines.each { |line| yield "  #{line}" }
      end

      if @wrapped.error_check?
        yield ''
        @wrapped.error_check(return_val: return_variable) do |line|
          yield "  #{line}"
        end
      end

      yield '  va_end( variadic_args );' if variadic?

      if @return_type.self_reference?
        yield '  return *this;'
      elsif @spec['return']['type'] != 'void' && !returns_call_directly?
        yield '  return return_val;'
      end

      yield '}'
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

    # The name of the function.
    def name
      @spec['name']
    end

    # A string with the parameter list for this function.
    def param_list
      ParamSpec.signature(@params, self)
    end

    # The name of the function with the class name, if it exists.
    def qualified_name
      if @owner.is_a?(ClassSpec)
        "#{@owner.name}::#{name}"
      else
        name
      end
    end

    # Gives an expression for calling a given parameter within this function.
    # Equivalent structs and pointers are resolved, as well as casts between
    # types if they are known within the scope of this function.
    def resolve_wrapped_param(param_spec)
      used_param = @params.find { |p| p.name == param_spec['value'] }

      if param_spec['value'] == EQUIVALENT_STRUCT_KEYWORD
        @owner.this_struct
      elsif param_spec['value'] == EQUIVALENT_POINTER_KEYWORD
        @owner.this_struct_pointer
      elsif param_spec['value'] == '...'
        'variadic_args'
      elsif castable?(param_spec)
        param_class = @owner.type(used_param.type)
        param_class.cast(used_param.name,
                         param_spec['type'],
                         used_param.type)
      else
        param_spec['value']
      end
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

    # Calls return_expression on the return type of this function. +func_name+
    # is passed to return_expression if provided.
    def return_expression(func_name: name)
      if @constructor || @destructor
        signature(func_name: func_name)
      else
        resolved_return.return_expression(self, func_name: func_name)
      end
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

    private

    # True if the return value of the wrapped call needs to be captured in a
    # local variable.
    def capture_return?
      !@constructor &&
        @wrapped.use_return? || returns_return_val?
    end

    # True if the provided wrapped param spec can be cast to when used in this
    # function.
    def castable?(wrapped_param)
      param = @params.find { |p| p.name == wrapped_param['value'] }

      !param.nil? &&
        !wrapped_param['type'].nil? &&
        @owner.type?(param.type)
    end

    # Raises an exception if this function cannot be defined as is. Returns
    # true otherwise.
    def definable_check
      if @wrapped.nil?
        raise UndefinableSpec, 'no wrapped function or code was specified'
      end

      true
    end

    # Yields a declaration of each local variable used by the function.
    def locals
      yield 'va_list variadic_args;' if variadic?

      if capture_return?
        wrapped_type = resolve_type(@wrapped.return_val_type)
        yield "#{wrapped_type.variable('return_val')};"
      end
    end

    # The resolved type of the return type.
    def resolved_return
      @return_type.resolve(self)
    end

    # The function to use to create the return value of the function.
    def return_cast(value)
      if @return_type == @wrapped.return_val_type
        value
      elsif @spec['return']['overloaded']
        "new#{@spec['return']['type'].chomp('*').strip} ( #{value} )"
      else
        resolved_return.cast_expression(value)
      end
    end

    # The name of the variable holding the return value.
    def return_variable
      if @constructor
        'this->equivalent'
      else
        'return_val'
      end
    end

    # True if the function returns the result of the wrapped function call
    # directly without any after actions.
    def returns_call_directly?
      !@constructor &&
        !@destructor &&
        !%w[void self-reference].include?(@spec['return']['type']) &&
        !@wrapped.error_check?
    end

    # True if the function returns the return_val variable.
    def returns_return_val?
      !@return_type.self_reference? &&
        @spec['return']['type'] != 'void' &&
        !returns_call_directly?
    end

    # The expression containing the call to the underlying wrapped function.
    def wrapped_call_expression
      call = @wrapped.call_from(self)

      if @constructor
        "this->equivalent = #{call}"
      elsif @wrapped.error_check?
        "return_val = #{call}"
      elsif returns_call_directly?
        "return #{return_cast(call)}"
      else
        call
      end
    end
  end
end
