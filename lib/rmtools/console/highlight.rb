# encoding: utf-8
RMTools::require 'console/coloring'

class String
  
  def find_hl(pat, range=1000)
    idx = case pat
      when String;   index pat
      when Regexp; self =~ pat
      else raise TypeError, "pattern must be string or regexp"
    end
    puts self[[idx-range, 0].max, 2*range].ghl(pat)
    idx
  end
  
  def find_all_hl(pat, range=1000)
    target = Regexp(
      ".{#{range}}#{pat.is(Regexp) ? pat.source : pat}.{#{range}}", 
      pat.is(Regexp) ? pat.options : 0)
    matches = scan(target)
    puts matches.ghls(pat)
    matches.size
  end
  
end