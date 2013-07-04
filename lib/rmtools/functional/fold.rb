# encoding: utf-8
module Enumerable

  def foldl(o, m=nil)
    case o
    when Proc
      block_given? ?
        reduce(m && yield(m)) {|m, i| m ? o.call(m, yield(i)) : yield(i)} : 
        reduce(m) {|m, i| m ? o.call(m, i) : i}
    when Symbol
      block_given? ?
        reduce(m && yield(m)) {|m, i| m ? m.__send__(o, yield(i)) : yield(i)} : 
        reduce(m) {|m, i| m ? m.__send__(o, i) : i}
    else TypeError! o, Proc, Symbol
    end
  end
  alias :fold :foldl  

  def foldr(o, m=nil)
    case o
    when Proc
    block_given? ?
      reverse.reduce(m && yield(m)) {|m, i| m ? o.call(yield(i), m) : yield(i)} : 
      reverse.reduce(m) {|m, i| m ? o.call(i, m) : i}
    when Symbol
    block_given? ?
      reverse.reduce(m && yield(m)) {|m, i| m ? yield(i).__send__(o, m) : yield(i)} : 
      reverse.reduce(m) {|m, i| m ? i.__send__(o, m) : i}
    else TypeError! o, Proc, Symbol
    end
  end

end