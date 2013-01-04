# Overwrites slow ActiveSupport ActiveSupport::JSON.encode by faster Yajl or JSON libraries
require 'active_support/core_ext/object/to_json'
begin
  require 'yajl' 
  
  [Array, Hash, String].each do |klass|
    klass.class_eval do
      def to_json(*)
        Yajl::Encoder.encode self
      end
    end
  end
  
  class String    
    # the opposite of #to_json
    def from_json(options={}) # :symbolize_keys
      Yajl::Parser.parse self, options
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
  # handy when data may not be encodable (active_record objects, recursive structures, etc)
  def to_json_safe(options=nil)
    timeout(10) {to_json(options)}
  end  
end