# Changelog
All notable changes to wrapture will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased
 - Ruby class generation.
 - Python class generation.
 - Perl class generation.

## [0.3.0] - 2019-08-24
### Added
 - Examples of basic usage and features.
 - Option to give a class-level include list.
 - Include lists may now be either a single string or a list.
 - Structs are now described in the StructSpec class.
 - Installation and dependency notes to README.
 - Scope class to describe a collection of classes.
 - `includes` property for function parameters.
 - `bin/wapture` now accepts multiple input files.
 - Version field in specs for backwards compatibility.

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
