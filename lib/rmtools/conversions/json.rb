# Overwrites slow ActiveSupport ActiveSupport::JSON.encode by faster Yajl or JSON libraries
if ActiveSupport.version.to_s < '4'
  require 'active_support/core_ext/object/to_json'
else
  require 'active_support/core_ext/object/json'
end

begin
  require 'yajl' 
  
  [Array, Hash, String].each do |klass|
    klass.class_eval do
      # @ options : {:pretty, :indent => string}
      def to_json(options={})
        Yajl::Encoder.encode self, options
      end
    end
  end
  
  class String    
    # the opposite of #to_json
    # @ options : {:symbolize_keys, :allow_comments, :check_utf8}
    def from_json(options={})
      Yajl::Parser.parse self, options
    end
  end
  
  # it may not be needed at all, though I've seen one gem that trying to use these methods
  module Yajl
    def self.parse(*args)
      Parser.parse(*args)
    end
    
    def self.encode(*args)
      Encoder.encode(*args)
    end
  end
  
rescue LoadError
  if defined? JSON
    
    [Array, Hash].each do |klass|
      klass.class_eval do
        def to_json(options=nil)
          JSON.unparse self, options
        end
      end
    end
    
    # This is only case where JSON.unparse does not work (and for only few versions of json stdlib)
    begin
      JSON.unparse ActiveSupport::OrderedHash
    rescue
      class ActiveSupport::OrderedHash
        # nothing lost here since javascript engines (at least Webkit) doesn't order objects      
        def to_json(options=nil)
          JSON.unparse({}.merge!(self))#, options)
        end
      end
    end
    
    class String
      # the opposite of #to_json
      def from_json
        JSON.parse self
      end
    end
    
  else
    
    class String
      # the opposite of #to_json
      def from_json
        ActiveSupport::JSON.decode self
      end
    end
  
  end
end
  
class Object  
  # handy when data may appear non-encodable (active_record objects, recursive structures, etc)
  def to_json_safe(options=nil, timeout: 10)
    timeout(timeout) {to_json(options)}
  end  
end