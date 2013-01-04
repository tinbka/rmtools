# encoding: utf-8
RMTools::require 'conversions/string'

class String
  CALLER_RE =    %r{^(.*?([^/\\]+?))#{	    # ( path ( file ) ) 
                              }:(\d+)(?::in #{	      # :( line )[ :in
                              }`(block (?:\((\d+) levels\) )?in )?(.+?)'#{   # `[ block in ] ( closure )' ]
                            })?$}
  SIMPLE_CALLER_RE =    %r{^(.*?([^/\\]+?))#{	    # ( path ( file ) ) 
                              }:(\d+)(?::in #{	      # :( line )[ :in
                              }`(.+?)'#{   # `( closure )' ]
                            })?$}
  URL_RE = %r{^((?:([^:]+)://)#{	            #  ( protocol
                      }([^/:]*(?::(\d+))?))?#{	  #  root[:port] )
                      }((/[^?#]*?(?:\.(\w+))?)#{	#  ( path[.( fileext )]
                      }(?:\?(.*?))?)?#{	              #  [?( query params )] )   
                      }(?:#(.+))?#{	                  #  [ #( anchor ) ]
                    }$}
  IP_RE           = /\d+\.\d+\.\d+\.\d+(?::\d+)?/
  IP_RANGE_RE = /(\d+\.\d+\.\d+\.\d+)\s*-\s*(\d+\.\d+\.\d+\.\d+)/
    
    def parse(as)
      case as
        when :uri
          m = match URL_RE
          !m || m[0].empty? ?
            {  'href'	        => self  } : 
            {	'href'	      => self,
                'root'	      => m[1],
                'protocol'	=> m[2],
                'host'	      => m[3], 
                'port'	      => m[4] ? m[4].to_i : 80,
                'fullpath'	=> m[5] || '/',
                'pathname'	=> m[5] || '/',
                'path'	      => m[6] || '',
                'ext'	        => m[7],
                'query'	      => m[8] && m[8].to_params(false),
                'anchor'	    => m[9] }
        when :caller
          m = match CALLER_RE
          !m || m[0].empty? ? nil : 
            {  'path' => m[1],
                'file' => m[2],
                'line' => m[3].to_i,
                'block_level' => m[4] && (m[5] || 1).to_i, # > 1.9
                'func' => m[6],
                'fullpath' => m[1] =~ /[\(\[]/ ? 
                  m[1] : 
                  File.expand_path(m[1])     }
        when :ip;          self[IP_RE]
        when :ip_range; (m = match IP_RANGE_RE) && m[1]..m[2]
        else raise ArgumentError, "Incorrect flag. Correct flags: :uri, :caller, :ip, :ip_range"
      end
    end
    
    def parseuri
      deprecate_method "Use String#parse(:uri) instead."
      parse :uri
    end
    
    def parseip(range=nil)
      deprecate_method "Use String#parse(:ip#{'_range' if range}) instead."
      parse :"ip#{'_range' if range}"
    end
    
end