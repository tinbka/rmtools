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
  spec.description   = %q{RMTools is applied library made primarily for debug and text/arrays/files processing}
  spec.summary       = %q{Code less, do more!}
  spec.homepage      = "https://github.com/tinbka/rmtools"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  # nonetheless, for this gem spec.files() returns [] after installation
  spec.require_paths = ["lib"]
  
  spec.add_runtime_dependency "activesupport"
  #unless ext_files_not_modified 'rmtools', RMTools::VERSION
    spec.extensions << 'ext/extconf.rb'
  #end

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
