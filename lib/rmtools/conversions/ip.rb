# encoding: utf-8
require 'scanf'

class String
  
  def from_ip(range=nil)
    int = to_i
    return int if int.to_s == self
    if range
      arr = []
      split(' - ').each {|s|
        res = s.scanf '%d.%d.%d.%d'
        arr << (res[0] << 24) + (res[1] << 16) + (res[2] << 8) + res[3]
      }
      "ip between #{arr[0]} and #{arr[1]}"
    else
      res = scanf '%d.%d.%d.%d'
      (res[0] << 24) + (res[1] << 16) + (res[2] << 8) + res[3]
    end
  end
  
  def to_ip
    from_ip.to_ip
  end
  
  def mask_ip(val)
    int = from_ip
    if val < 0
      maskv = 32+val
    else
      maskv = val
      val = 32 - val
    end
    "#{(int - (int & 2**val - 1)).to_ip}/#{maskv}"
  end
  
  def scan_ip
    scan(/(\d+\.\d+\.\d+\.\d+)(?::(\d+))?/)
  end
  
  def parseips
    deprecation "Use #scan_ip"
    scan_ip
  end
  
end

class Integer
  
    def from_ip
      self
    end
    
    def to_ip
      "#{(self >> 24) & 0xff}.#{(self >> 16) & 0xff}.#{(self >> 8) & 0xff}.#{self & 0xff}"
    end
    
    def mask_ip(val)
      if val < 0
        maskv = 32+val
      else
        maskv = val
        val = 32 - val
      end
      self - (self & 2**val - 1)
    end
    
end

class Range
  
    def mask_ip
      i = nil
      31.downto(12) {|i|
        lm = last.mask_ip(i)
        break if first.mask_ip(i) == lm and (last+1).mask_ip(i) != lm
        i = nil
      }
      i || 32
    end

end