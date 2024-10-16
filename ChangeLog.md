# Changelog
All notable changes to wrapture will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
For a detailed look at the project's future, including planned features and bug
fixes, check out the
[roadmap](https://github.com/goatshriek/wrapture/blob/master/docs/roadmap.md).

## [0.6.0 - 2021-08-17
### Added
 - Support for Ruby 3.0
 - RBS signatures.
 - Python wrapper generation.

### Removed
 - Ruby 2.4 is no longer supported.

## [0.5.0] - 2020-12-15
### Fixed
 - Return values are now properly declared, captured, and returned as needed.
 - `bin/wrapture` now checks the version number of specs it processes.

### Removed
 - Ruby 2.3 is no longer supported.

## [0.4.2] - 2020-05-11
### Fixed
 - Functions that return function pointers now cast the return correctly instead
   of containing non-valid code
   ([issue #76](https://github.com/goatshriek/wrapture/issues/76)).
 - Return value types are now valid types when they are given using a special
   keyword in the spec, such as `equivalent-struct-pointer`. The types are now
   resolved based on the keyword if one is used
   ([issue #77](https://github.com/goatshriek/wrapture/issues/77)).
 - The list `Wrapture::KEYWORDS` now contains the value in
   `Wrapture::SELF_REFERENCE_KEYWORD`.
 - `throw-exception` actions with no parameters for the constructor no longer
   cause an error
   ([issue #78](https://github.com/goatshriek/wrapture/issues/78)).
 - Return values are correctly switched to the equivalent struct in
   constructors instead of using `return_val`, which was not actually set
   ([issue #84](https://github.com/goatshriek/wrapture/issues/84)).

## [0.4.1] - 2020-04-24
### Fixed
 - Constructor and destructor definitions no longer have a type of 'void'
   provided ([issue #72](https://github.com/goatshriek/wrapture/issues/72)).

## [0.4.0] - 2020-04-23
### Added
 - Inequality conditions for rules (less-than, less-than-equal, greater-than,
   greater-than-equal).
 - Classes who's parent wraps the same equivalent struct will re-use the
   equivalent pointer member of the parent class.
 - Pointer classes who's parent wraps the same equivalent struct will use the
   parent's pointer constructor as the initializer for their own pointer
   constructor.
 - Classes may be defined without an equivalent struct.
 - Specs can contain templatized sections to avoid duplicated sections.
 - Documentation can be added to generated classes, functions, and constants.
 - Return type may be `self-reference` to facilitate method chaining.
 - Conversions can be made from references and pointers to wrapped classes to
   their equivalent structs.
 - Support for ruby 2.7.
 - Functions may name the last parameter `...` to generate a variadic function.
 - Enumerations can be wrapped by providing an `enums` list in a spec or scope.
 - Support for function pointer types via new TypeSpec class.

### Fixed
 - Classes with no `name` member raise a MissingSpecKey exception.

## [0.3.0] - 2020-01-01
### Added
 - Examples of basic usage and features.
 - Option to give a class-level include list.
 - Include lists may now be either a single string or a list.
 - Structs are now described in the StructSpec class.
 - Wrapped functions are now described in the WrappedFunctionSpec class.
 - Installation and dependency notes to README.
 - Scope class to describe a collection of classes.
 - `includes` property for function parameters.
 - `bin/wapture` now accepts multiple input files.
 - `version` field in specs for explicit support checks.
 - Classes may have a parent class specified.
 - Struct members may have default values specified to allow for the generation
   of a default constructor.
 - Support for virtual functions.
 - Pointer wrapper classes are by default given a constructor that takes a
   pointer to the equivalent struct and wraps it in the class.
 - Structs can be wrapped by the best matching wrapper via the `newClassName`
   family of functions.
 - Classes can be explicitly specified as pointer or struct wrapping classes
   using the `type` property.
 - Return values are not casted if the generated function and wrapped function
   have the same return type.
 - Errors can be detected and converted to exceptions to throw.

### Fixed
 - `bin/wrapture` is now executable.
 - Class constants are indented properly.
 - Missing namespaces are caught before code generation.

## [0.2.2] - 2019-07-06
### Fixed
 - Allow failures of Mac OSX JRuby CI builds due to RVM problems.

## [0.2.1] - 2019-06-16
### Fixed
 - Add `--no-document` to CI scripts due to missing Darkfish support on
   TruffleRuby.

## [0.2.0] - 2019-05-27
### Added
 - Additional project information to gemspec.
 - Integration with Travis CI.
 - ClassSpec, FunctionSpec, and ConstantSpec classes.
 - SonarCloud integration.
 - Test coverage of 100%.

## [0.1.0] - 2019-05-02
### Added
 - C++ class generation with member functions and constants.
