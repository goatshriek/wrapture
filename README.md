# Wrapture

[![Travis Build Status](https://travis-ci.org/goatshriek/wrapture.svg?branch=master)](https://travis-ci.org/goatshriek/wrapture)
[![Coverage Report](https://codecov.io/gh/goatshriek/wrapture/branch/master/graph/badge.svg)](https://codecov.io/gh/goatshriek/wrapture)

A tool for generating object-oriented language wrappers for C code.

Wrapture uses YAML files that describe the C code being wrapped and the output
language interface.

## What about SWIG?

[SWIG](http://www.swig.org) provides a very similar functionality by wrapping C
code in higher-level languages. SWIG can parse C code and detect functions
constants, and other symbols to wrap automatically. Wrapture is a simpler and
more deliberate tool - the author must write an interface description in YAML
outlining all of these things. This results in a much more concise class
definition that feels more native to the output language than an auto-generated
interface. Wrapture also has much more limited language and feature support than
SWIG.
