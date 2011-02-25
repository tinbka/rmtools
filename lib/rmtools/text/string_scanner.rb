# encoding: utf-8
require 'strscan'

class StringScanner
  attr_reader :last
  
  def each(re, cbs=nil, &cb)
    @last = 0
    res = scan_until re
    if cbs
      if cbs.keys.compact[0].is Fixnum
        while res
          if cb = cbs[matched.ord]
            cb[self]
            @last = pos
            res = !eos? && scan_until(re)
          else break
          end
        end
      else
        while res
          if cb = cbs.find {|pattern, proc| pattern and pattern.in matched}
            # patterns must be as explicit as possible
            cb[1][self]
            @last = pos
            res = !eos? && scan_until(re)
          else break
          end
        end
      end
    else
      while res
          cb[self]
          @last = pos
          res = !eos? && scan_until(re)
      end
    end
    if (cb = cbs[nil]) and !eos?
      cb[tail]
    end
  end
  
  def head
    string[@last...pos-matched.size]
  end
  
  def tail
    string[pos..-1]
  end
  
  def hl_next(re)
    (res = scan_until re) && RMTools.hl(string[pos-1000..pos+1000], res)
  end
  
  def self.each string, *args, &b
    new string, *args, &b
  end
  
end
