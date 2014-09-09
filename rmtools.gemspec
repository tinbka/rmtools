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

  spec.files         = `git ls-files`.split
  # nonetheless, for this gem spec.files() returns [] after installation
  spec.require_paths = ["lib"]
  
  # we want to overwrite some its methods
  spec.extensions << 'ext/extconf.rb'
end
