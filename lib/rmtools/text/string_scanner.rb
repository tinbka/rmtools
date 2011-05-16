# encoding: utf-8
require 'strscan'

class StringScanner
  attr_reader :last
  __init__
  
  # #each( <Regexp>, { <0..255 | :~ | nil> => ->{|self|}, ... } )
  # #each( <Regexp>, [ [ <Regexp>, ->{|self, <MatchData>|} ], ... ] )
  # #each( <Regexp> ) {|self|}
  # Example:
  #   ss = StringScanner.new xpath
  #   ss.each %r{\[-?\d+\]|\{[^\}]+\}}, 
  #     ?[ => lambda {|ss| 
  #       if node; node = FindByIndex[node, nslist, ss]
  #       else     return []     end  }, 
  #     ?{ => lambda {|ss| 
  #       if node; node = FindByProc[node, nslist, ss]
  #       else     return []     end  },
  #     nil => lambda {|str|
  #       node = node.is(Array) ?
  #         node.sum {|n| n.__find(str, nslist).to_a} : node.__find(str, nslist) 
  #     }
  def each(re, cbs=nil, &cb)
    @last = 0
    res = scan_until re
    if cbs
      if cbs.is Hash
        while res
          if cb = cbs[matched.ord] || cbs[:~]
            cb[self]
            @last = pos
            res = !eos? && scan_until(re)
          else break
          end
        end
        if !eos? and cb = cbs[nil]
          cb[tail]
        end
      else
        while res
          if cb = cbs.find {|pair| pair[0] and matched[pair[0]]}
            # patterns should be as explicit as possible
            cb[1][self, $~] if cb[1]
            @last = pos
            res = !eos? && scan_until(re)
          else break
          end
        end
        if !eos? and cb = cbs.find {|pair| pair[0].nil?}
          cb[1][tail]
        end
      end
    else
      while res
        cb[self]
        @last = pos
        res = !eos? && scan_until(re)
      end
    end
  end
  
  def head
    string[@last...pos-matched_size]
  end
  
  alias tail post_match
  
  def hl_next(re)
    (res = scan_until re) && Painter.hl(string[[pos-1000, 0].max..pos+1000], res)
  end
  
  def next_in(n)
    string[pos+n-1, 1]
  end
  
  def prev_in(n)
    string[pos-matched_size-n, 1]
  end
  
  def +; string[pos, 1] end
  
  def -; string[pos-matched_size-1, 1] end
  
  def self.each string, *args, &b
    new(string).each *args, &b
  end
  
end
