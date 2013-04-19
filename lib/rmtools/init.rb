# encoding: utf-8
require 'active_support'
require File.expand_path('require', File.dirname(__FILE__))

module RMTools
  %w[version core enumerable text time functional
    conversions ip lang rand console
    fs db xml
    ../rmtools.so
  ].each {|file| RMTools::require file}
end
