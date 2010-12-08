# encoding: utf-8
class Hash
  
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
    alias :plus :+ end
  
  def +(str)
    plus str.to_s
  end
  
end