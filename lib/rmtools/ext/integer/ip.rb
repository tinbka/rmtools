module RMTools
  module Integer
    module IP
  
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
  end
end