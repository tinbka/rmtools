# encoding: utf-8
# js hash getter/setter and string concat logic
class Hash
  alias :throw_no :method_missing
  
  # hash = {}
  # hash.abc = 123
  # hash # => {"abc"=>123}
  # hash.abc # => 123
  # hash.unknown_function(321) # => raise NoMethodError
  # hash.unknown_function # => nil
  # hash[:def] = 456
  # hash.def # => 456
  def method_missing(method, *args)
    str = method.to_s
    if str =~ /=$/
      self[str[0..-2]] = args[0]
    else
      throw_no method if !args.empty? or str =~ /[!?]$/
      a = self[str]
      (a == default) ? self[method] : a
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