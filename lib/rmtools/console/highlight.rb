# encoding: utf-8
RMTools::require 'console/coloring'

class String
  
  def find_hl(pat, range=1000) idx = case pat
    when String;   index pat
    when Regexp; self =~ pat
    else raise TypeError, "pattern must be string or regexp"
    end
    puts Painter.ghl(self[[idx-range, 0].max, 2*range], pat)
  end
  
end