# encoding: utf-8
class Numeric
  
  # ceil-round to i-fold
  def ceil_to(i)
    self + i - self % i 
  end
  
  # floor-round to i-fold
  def floor_to(i)
    self - self % i
  end
  
  # closest-round to i-fold
  def round_to(i)
    ceil = ceil_to i
    floor = floor_to i
    ceil - self < self - floor ? ceil : floor
  end
  
  # is self lies between two numerics
  def between(min, max)
    min < self and self < max
  end
  
  # is self multiple of numeric
  def mult_of(subj)
    self % subj == 0
  end
  
  def hex
    sprintf "%x", self
  end
  
end

module Math

  def logb(b, x)
    log(x)/log(b)
  end

end