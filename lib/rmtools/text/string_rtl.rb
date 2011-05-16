RMTools::require 'text/regexp'

class String
  
  # rightmost #sub
  def rsub(from, to=nil, &block)
    if block
      reverse.sub(from.reverse) {|m| block[m.reverse].reverse}.reverse
    else
      q = to.scan(/\\\d(\D|$)/).size+1
      to = to.reverse
      to.gsub!(/(^|\D)(\d)\\/) {"#$1\\#{q-$2.to_i}"} if q > 1
      reverse.sub(from.reverse, to).reverse
    end
  end

  # in-place #rsub
  def rsub!(from, to=nil, &block)
    new = rsub from, to, &block
    new == self ? nil : replace(new)
  end
    
  # lookbehind #split
  def rsplit(splitter=$/, qty=0)
    reverse.split(splitter.reverse, qty).reverse.reverses
  end
  
end