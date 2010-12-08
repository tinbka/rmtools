require 'fileutils'
require 'iconv'
require 'cgi'
require 'set'
require 'strscan'

# why did I put it in here?
# require "bundler/setup"

# being required *after* rmtools/random it overrides some of a functions and then whine about they are "deprecated", huh
require 'activesupport' rescue nil

module RMTools
  rmtools = File.expand_path(__FILE__)[0..-4]
  require "#{rmtools}/string_to_proc"
  [ 'string_to_proc',
    'string', 'object', 'module', 'enum', 'array', 'hash',
    'numeric',  'stringscanner',  'proc',  'io',  'range',
      
    'js',	        #  js hash getter/setter and string concat logic
    
    'boolean',	  # {obj.b -> self or false} with python logic
                  # and native boolean #to_i and #<=>
                  # Since 2.3.8 active_support has analogue: #presence
                  # BTW, why so slow?
                        
    'logging',  'coloring', # lazy logger
                            # with caller processing and highlighting
  #  'traceback',	# python-like traceback for exceptions 
                  # uses ANSI coloring; kinda buggy, so better
                  # require 'rmtools/traceback' separately
      
                                       
    'printing', # transparent print: print text (or object info) and erase it
    'limited_string',       # for compact string inspecting
    
    'binding',       # binding inspect
    'arguments',    # arguments parsing and types validation
    
    'cyrilic',  'cyr-time', # String & Regexp methods for Russian processing
    
    # some bicycles just for convenience
    'dumps',  'time',  'random'
  ].each {|f| require "#{rmtools}/#{f}"}
end

require "#{rmtools}/rmtools.so" rescue nil

$log = RMTools::RMLogger.new

# Comment out in case of any method conflicts
# Library methods use module functions explicitly
class Object; include RMTools end
