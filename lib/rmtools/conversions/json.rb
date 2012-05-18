<<-original
[Object, Array, FalseClass, Float, Hash, Integer, NilClass, String, TrueClass].each do |klass|
  klass.class_eval do
    # Dumps object in JSON (JavaScript Object Notation). See www.json.org for more info.
    def to_json(options = nil)
      ActiveSupport::JSON.encode(self, options)
    end
  end
end
original
# Overwrites slow ActiveSupport ActiveSupport::JSON.encode by faster 1.9 stdlib JSON library
if RUBY_VERSION > '1.9'
  [Array, Hash].each do |klass|
    klass.class_eval do
      def to_json(options=nil)
        JSON.unparse(self, options)
      end
    end
  end
  
  class ActiveSupport::OrderedHash
      # nothing lost here since javascript engines (at least Webkit) doesn't order objects
    def to_json(options=nil)
      JSON.unparse({}.merge!(self), options)
    end
  end
  
  class String
    # the opposite of #to_json
    def from_json
      JSON.parse self
    end
  end
  
else
  
  def from_json
    ActiveSupport::JSON.decode self
  end    
  
end
  
class Object
  
  def to_json_safe(options=nil)
    timeout(10) {to_json(options)}
  end
  
end