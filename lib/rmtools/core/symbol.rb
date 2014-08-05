# encoding: utf-8
class Symbol
  
  def split(splitter='_')
    to_s.split splitter
  end
  alias :/ :split
  
  def method_missing(method, *args, &block)
    if ''.respond_to? method
      to_s.__send__ method, *args, &block
    else
      super
    end
  end
  
end