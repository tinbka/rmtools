# encoding: utf-8
RMTools::require 'rand/enum'

class Range
  
  def rand
    self.begin + Kernel.rand(size)
  end

  def randseg
    (a = rand) > (b = rand) ? b..a : a..b
  end
  
end