# Testing Wrapture
Tests in Wrapture use the `minitest` gem, and fall into two categories: unit
tests and integration tests. The default rake task runs the unit tests by
default, but all tests can be run at once with the `test` task.


# Unit Tests
Unit tests are held in the `test/unit` directory, and can be run with the
`test:unit` rake task. These tests are meant to focus on isolated portions
of Wrapture's functionality, and can be run in any environment that
Wrapture can.


## Integration Tests
Integration tests are held in the `test/integration` directory and are run
with the `test:integration` task. Integration tests are end-to-end, generating
wrappers, building the wrapped library and the wrappers, and testing the
functionality of the wrapper.

Because they build and run both wrapped libraries and their wrappers,
integration tests have many more dependencies than Ruby. They also provide a
broader test of overall functionality, for example ensuring that generated code
compiles correctly.


## Test Fixtures
Fixtures for tests are kept in the `test/fixtures` directory. These are YAML
files that can be loaded as Wrapture specs, and are used by the tests to quickly
create specs to test various pieces of functionality. These specs may also serve
as examples of various ways of defining Wrapture specs. There are several
helpers for using fixtures in the `test/fixture.rb` file, including methods to
quickly load specs and/or build systems by name.

Subdirectories of `test/fixtures` hold complete projects: source code for a
library to be wrapped, a build system describing how to compile the wrapped
library in `build.yml`, a spec for wrapping the library in `spec.yml`, and
usage programs that exercise generated wrappers, for example `cpp_usage.cpp`.
These fixtures may be used by any tests, but are primarily intended for
integration tests.

The usage programs in these subdirectories should not print output, and should
instead exit with a non-zero value if something does not work properly.

The `test/fixtures/invalid` directory does not have a project, but instead
holds specs that are not valid in some way, and will cause errors when
loaded by Wrapture.
