# encoding: utf-8
class Symbol
  
  def +(str)
    to_s + str
  end
  
  def split(splitter='_')
    to_s.split splitter
  end
  alias :/ :split
  
  alias :throw_no :method_missing
  def method_missing(method, *args, &block)
    if ''.respond_to? method
      to_s.__send__ method, *args, &block
    else
      throw_no method
    end
  end
  
end