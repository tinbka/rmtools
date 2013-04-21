# encoding: utf-8
require 'active_support'
require 'rmtools/require'
%w[version core enumerable text time functional
  conversions lang rand console
  fs db xml dev_min
  ../rmtools.so
].each {|file| RMTools::require file}