# encoding: utf-8
require 'active_support'

module RMTools
  dir = File.dirname __FILE__
  VERSION = IO.read(File.join dir, '..', '..', 'Rakefile').match(/RMTOOLS_VERSION = '(.+?)'/)[1]
  
  require File.expand_path('require', dir)
  [ 'core', 'enumerable', 'text', 'time', 'functional', 
    'conversions', 'ip', 'lang', 'rand',
    'fs', 'db', 'xml',
    '../rmtools.so'
  ].each {|file| RMTools::require file}
end

# Comment out in case of any method conflicts
# Library methods use module functions explicitly
class Object; include RMTools end

# default logger now initialized in debug/logging