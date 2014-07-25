# encoding: utf-8

# Javascript hash getter/setter and string concat logic
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
  #
  # This priority should be stable, because 
  def method_missing(method, *args)
    str = method.to_s
    if str =~ /=$/
      self[str[0..-2]] = args[0]
    elsif !args.empty? or str =~ /[!?]$/
      throw_no method 
    else
      a = self[method]
      (a == default) ? self[str] : a
    end
  end
  
  # Redefine since these methods are deprecated anyway
  def type
    a = self[:type]
    (a == default) ? self['type'] : a
  end
  def id
    a = self[:id]
    (a == default) ? self['id'] : a
  end

end

class String
  if !method_defined? :plus
    alias :plus :+ 
  
    #   immutable:
    # '123' + 95 # => '12395'
    # '123'.plus 95 # => raise TypeError
    def +(str)
      plus str.to_s
    end
    
    #   mutable:
    # '123' << 95 # => '12395'
    # '123'.concat 95 # => '123_'
    def <<(str)
      concat str.to_s
    end
  end
  
end