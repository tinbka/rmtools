# encoding: utf-8
class String
  
  def bytes
    arr = []
    each_byte {|b| arr << b.hex}
    arr
  end
  
  def to_limited len=100
    LimitedString.new self, len
  end
  
end

class Indent < String
  attr_reader :indent

  def initialize(indent='  ')
    @indent = indent
    super ''
  end
  
  def +@
    self << @indent
  end
  
  def -@
    self.chomp! @indent
  end
  
  def i(&block)
    +self
    res = yield
    -self
    res
  end

end

# Compact string inspect
class LimitedString < String
  attr_reader :len
  __init__
  
  def initialize str="", len=100
    @len = len
    super str
  end
  
  def inspect
    @len ||= 100
    size > @len ? String.new(self[0...@len]+"…").inspect : super
  end
  
end
