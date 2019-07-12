# Wrapture

[![Travis Build Status](https://travis-ci.org/goatshriek/wrapture.svg?branch=master)](https://travis-ci.org/goatshriek/wrapture)
[![Coverage Report](https://codecov.io/gh/goatshriek/wrapture/branch/master/graph/badge.svg)](https://codecov.io/gh/goatshriek/wrapture)
[![SonarCloud Status](https://sonarcloud.io/api/project_badges/measure?project=wrapture&metric=alert_status)](https://sonarcloud.io/dashboard?id=wrapture)
[![Apache 2.0 License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A tool for generating object-oriented language wrappers for C code.

Wrapture uses YAML files that describe the C code being wrapped and the output
language interface.

## Installation and Dependencies

Wrapture is available on RubyGems.org and can be installed with a simple:

```ruby
gem install wrapture
```

Wrapture is packaged with bundler, so if you want to work on the source directly
you can get all dependencies with a simple `bundle install`.

Running the examples will require an environment that supports the target
language, for example a compiler like `g++`for the C++ examples. You will need
to install this on your own, as there is currently nothing in Wrapture to
manage all of the target languages supported.

## What about SWIG?

[SWIG](http://www.swig.org) provides a very similar functionality by wrapping C
code in higher-level languages. SWIG can parse C code and detect functions
constants, and other symbols to wrap automatically. Wrapture is a simpler and
more deliberate tool - the author must write an interface description in YAML
outlining all of these things. This results in a much more concise class
definition that feels more native to the output language than an auto-generated
interface. Wrapture also has much more limited language and feature support than
SWIG.
