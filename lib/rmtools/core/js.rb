# encoding: utf-8
# js hash getter/setter and string concat logic
class Hash
  
  # hash = {}
  # hash.abc = 123
  # hash # => {"abc"=>123}
  # hash.abc # => 123
  # hash.unknown_function(321) # => raise NoMethodError
  # hash.unknown_function # => nil
  # hash[:def] = 456
  # hash.def # => 456
  def method_missing(met, *args)
    str = met.id2name
    if str[/=$/]
      self[str[0..-2]] = args[0]
    else
      raise NoMethodError, "undefined method `#{str}' for #{self}:#{(self.class)}" if !args.empty?
      a = self[str]
      (a == default) ? self[met] : a
    end
  end

end

class String
  if !method_defined? :plus
    alias :plus :+ 
  
    #   immutable:
    # '123' + 95 # => '12395'
    # '123'.plus 95 # => raise TypeError
    #   mutable:
    # '123' << 95 # => '12395'
    # '123'.concat 95 # => '123_'
    def +(str)
      plus str.to_s
    end
    
    def <<(str)
      concat str.to_s
    end
  end
  
end