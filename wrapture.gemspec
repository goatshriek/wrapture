require File.expand_path('../lib/wrapture/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name        =  'wrapture'
  spec.version     =  Wrapture::VERSION
  spec.date        =  '2019-04-01'
  spec.summary     =  'wrap C in C++'
  spec.description =  'Wraps C code in C++.'
  spec.authors     =  ['Joel Anderson']
  spec.email       =  'joelanderson333@gmail.com'
  spec.files       =  Dir.glob("{lib,bin}/**/*").reject{|f| File.directory?(f) }
  spec.executables << 'wrapture'
  spec.homepage    =  'http://rubygems.org/gems/wrapture'
  spec.license     =  'Apache-2.0'

  spec.required_ruby_version = '>= 2.3'
  spec.add_development_dependency 'minitest'
  spec.add_development_dependency 'rake'

  if spec.respond_to?(:metadata)
    spec.metadata = {
      "bug_tracker_uri" => "https://github.com/goatshriek/wrapture/issues",
      "changelog_uri" => "https://github.com/goatshriek/wrapture/blob/master/ChangeLog.md",
      "source_code_uri" => "https://github.com/goatshriek/wrapture/"
    }
  end
end
