module RMTools
  module Range
    module IP
  
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
  end
end