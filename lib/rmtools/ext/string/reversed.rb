module RMTools
  module String
    module Reversed
  
      # rightmost #sub
      def rsub(from, to=nil, &block)
        if block
          reverse.sub(from.reverse) {|m| block[m.reverse].reverse}.reverse
        else
          q = to.scan(/\\\d(\D|$)/).size+1
          to = to.reverse
          to.gsub!(/(^|\D)(\d)\\/) {"#$1\\#{q-$2.to_i}"} if q > 1
          reverse.sub(from.reverse, to).reverse
        end
      end

      # in-place #rsub
      def rsub!(from, to=nil, &block)
        new = rsub from, to, &block
        new == self ? nil : replace(new)
      end
        
      # lookbehind #split
      def rsplit(splitter=$/, qty=0)
        reverse.split(splitter.reverse, qty).reverse.reverses
      end
        
      # leftmost chomp
      def lchomp(match=/\r\n?/)
        if index(match) == 0
          self[match.size..-1]
        else
          self.dup
        end
      end

      # in-place #lchomp
      def lchomp!(match=/\r\n?/)
        if index(match) == 0
          self[0...match.size] = ''
          self
        end
      end
      
    end
  end
end