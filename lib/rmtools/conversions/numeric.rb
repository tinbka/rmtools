# encoding: utf-8
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