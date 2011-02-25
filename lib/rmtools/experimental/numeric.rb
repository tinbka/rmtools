# encoding: utf-8
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
    
class Integer
  
  def digits
    nums = []
    while (int ||= self) > 0
      nums << int%10
      int /= 10
    end
    nums
  end
  
  def each_bit # descending order
    to_s(2).each_byte {|b| yield(b == 49)}
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

class Array
  
  def compile_int(base=10)
    int = 0
    pos = size
    each {|i| int += base**(pos -= 1) * i}
    int
  end
  
end
