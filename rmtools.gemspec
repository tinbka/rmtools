# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rmtools/version'
#require 'rmtools/install'

Gem::Specification.new do |spec|
  spec.name          = "rmtools"
  spec.version       = RMTools::VERSION
  spec.authors       = ["Sergey Baev"]
  spec.email         = ["tinbka@gmail.com"]
  spec.description   = %q{RMTools is a collection of helpers for debug, text/array/file processing and simply easing a coding process}
  spec.summary       = %q{Collection of helpers for debug, text/array/file processing and simply easing a coding process}
  spec.homepage      = "https://github.com/tinbka/rmtools"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  # nonetheless, for this gem spec.files() returns [] after installation
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency "activesupport"
  
  spec.extensions << 'ext/extconf.rb'

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
