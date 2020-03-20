# Changelog
All notable changes to wrapture will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
 - Ruby class generation.
 - Python class generation.
 - Perl class generation.

## [0.4.0] - 2020-03-20
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
 - Conversions can be made from references to wrapped classes to their
   equivalent types.

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
