# Wrapture
[![Github Actions Build Status](https://github.com/goatshriek/wrapture/actions/workflows/build.yml/badge.svg)](https://github.com/goatshriek/wrapture/actions?query=workflow%3Abuild)
[![Coverage Report](https://codecov.io/gh/goatshriek/wrapture/branch/latest/graph/badge.svg)](https://codecov.io/gh/goatshriek/wrapture)
[![SonarCloud Status](https://sonarcloud.io/api/project_badges/measure?project=goatshriek_wrapture&metric=alert_status)](https://sonarcloud.io/dashboard?id=goatshriek_wrapture)
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
to install these on your own, as there is currently nothing in Wrapture to
manage all of the target language environments.


## Contributing
Wrapture is still in the early stages of development, largely being driven by
support of [stumpless](https://github.com/goatshriek/stumpless). If you'd like
to contribute, please submit an issue with ideas of features that you think are
important, or share your thoughts on Twitter with
[#WraptureGem](https://twitter.com/search?q=%23WraptureGem)!

Once the structure of the project has solidified, there will be issues for
contributors of all skill levels to get involved with, so stay tuned!

