# encoding: utf-8
class Numeric
  
  def ceil_to(i)
    self + i - self%i 
  end
  
  def floor_to(i)
    self - self%i
  end
  
  def round_to(i)
    [ceil_to(i), floor_to(i)].max
  end
  
  def between(min, max)
    min < self and self < max
  end
  
  def mult_of(subj)
    self%subj == 0
  end
  
  def hex
    sprintf "%x", self
  end
  
end

module Math

  def logb(b, x) log(x)/log(b) end

end
    