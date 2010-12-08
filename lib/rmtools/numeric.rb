# encoding: utf-8
class Integer
  
  def digits
    nums = []
    while (int ||= self) > 0
      nums << int%10
      int /= 10
    end
    nums
  end
  
  def mult_of(subj) # allready implemented in ActiveSupport though
    self%subj == 0
  end
  
  def each_bit # descending order
    to_s(2).each_byte {|b| yield(b == 49)}
  end
  
  def blur_bm
    to_s(2).gsub(/.?1.?/) {|m| m.size==3?'111':'11'}.to_i(2)
  end
  
  def hex
    sprintf "%x", self
  end
  
  def to_array(base=10)
    int = self
    ary = []
    begin
      a = int.divmod base
      ary << a[1]
      int = a[0]
    end while int != 0
    ary.reverse!
  end
  
end

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
  
end    

class Float
  
  def partial(range=100)
    return to_i.to_s if to_i == self
    a = abs
    (2..range-1).each {|i| (1..range).each {|j|
        n = j.to_f/i
        break if n > a
        return "#{'-' if self != a}#{j}/#{i}" if n == a
    } }
    self
  end
      
end

module Math

  def logb(b, x) log(x)/log(b) end

end
    