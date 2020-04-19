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

require 'wrapture/comment'
require 'wrapture/constants'
require 'wrapture/errors'
require 'wrapture/param_spec'
require 'wrapture/scope'
require 'wrapture/wrapped_function_spec'

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
    # The hash must have the following keys:
    # name:: the name of the function
    # params:: a list of parameter specifications
    # wrapped-function:: a hash describing the function to be wrapped
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
    # The wrapped-function must have a 'name' key with the name of the function,
    # and a 'params' key with a list of parameters (each a hash with a 'name'
    # and 'type' key). Optionally, it may also include an 'includes' key with a
    # list of includes that are needed for this function to compile.
    #
    # The following keys are optional:
    # doc:: a string containing the documentation for this function
    # return:: a specification of the return value for this function
    # static:: set to true if this is a static function
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
      @wrapped = WrappedFunctionSpec.new(spec['wrapped-function'])
      @params = ParamSpec.new_list(@spec['params'])
      @return_type = TypeSpec.new(@spec['return']['type'])
      @constructor = constructor
      @destructor = destructor
    end

    # True if the function is a constructor, false otherwise.
    def constructor?
      @constructor
    end

    # A list of includes needed for the declaration of the function.
    def declaration_includes
      includes = @spec['return']['includes'].dup
      @params.each { |param| includes.concat(param.includes) }
      includes.uniq
    end

    # A list of includes needed for the definition of the function.
    def definition_includes
      includes = @wrapped.includes
      includes.concat(@spec['return']['includes'])
      @params.each { |param| includes.concat(param.includes) }
      includes << 'stdarg.h' if variadic?
      includes.uniq
    end

    # The name of the function.
    def name
      @spec['name']
    end

    # A string with the parameter list for this function.
    def param_list
      ParamSpec.signature(@params, self)
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

    # The signature of the function.
    def signature
      "#{name}( #{param_list} )"
    end

    # Yields each line of the declaration of the function, including any
    # documentation.
    def declaration
      doc.format_as_doxygen(max_line_length: 76) { |line| yield line }

      if @constructor || @destructor
        yield "#{signature};"
        return
      end

      modifier_prefix = if @spec['static']
                          'static '
                        elsif virtual?
                          'virtual '
                        else
                          ''
                        end

      abs_return = @return_type.absolute(self)
      yield "#{modifier_prefix}#{abs_return.return_expression(self)};"
    end

    # Gives the definition of the function to a block, line by line.
    def definition(class_name)
      yield "#{return_prefix}#{class_name}::#{signature} {"

      locals { |declaration| yield "  #{declaration}" }

      yield "  va_start( variadic_args, #{@params[-2].name} );" if variadic?

      if @wrapped.error_check?
        yield
        yield "  #{wrapped_call_expression};"
        yield
        @wrapped.error_check { |line| yield "  #{line}" }
      else
        yield "  #{wrapped_call_expression};"
      end

      yield '  va_end( variadic_args );' if variadic?

      yield '  return *this;' if @return_type.self?

      yield '}'
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

    # A resolved type name, given a TypeSpec +type+.
    def resolve_type(type)
      if type.equivalent_struct?
        TypeSpec.new("struct #{@owner.struct_name}")
      elsif type.equivalent_pointer?
        TypeSpec.new("struct #{@owner.struct_name} *")
      elsif type.self?
        TypeSpec.new("#{@owner.name}&")
      else
        type
      end
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

    # True if the provided wrapped param spec can be cast to when used in this
    # function.
    def castable?(wrapped_param)
      param = @params.find { |p| p.name == wrapped_param['value'] }

      !param.nil? &&
        !wrapped_param['type'].nil? &&
        @owner.type?(param.type)
    end

    # Yields a declaration of each local variable used by the function.
    def locals
      yield 'va_list variadic_args;' if variadic?
      yield "#{@wrapped.return_val_type} return_val;" if @wrapped.error_check?
    end

    # The function to use to create the return value of the function.
    def return_cast(value)
      if @spec['return']['type'] == @wrapped.return_val_type
        value
      elsif @spec['return']['overloaded']
        "new#{@spec['return']['type'].chomp('*').strip} ( #{value} )"
      else
        "#{@spec['return']['type']} ( #{value} )"
      end
    end

    # The return type prefix to use for the function definition.
    def return_prefix
      if @constructor || @destructor
        ''
      elsif @return_type.pointer?
        resolve_type(@return_type).name
      else
        "#{resolve_type(@return_type).name} "
      end
    end

    # True if the function returns the result of the wrapped function call.
    def returns_call_result?
      !@constructor && !@destructor &&
        !%w[void self-reference].include?(@spec['return']['type'])
    end

    # The expression containing the call to the underlying wrapped function.
    def wrapped_call_expression
      call = @wrapped.call_from(self)

      if @constructor
        "this->equivalent = #{call}"
      elsif @wrapped.error_check?
        "return_val = #{call}"
      elsif returns_call_result?
        "return #{return_cast(call)}"
      else
        call
      end
    end
  end
end
