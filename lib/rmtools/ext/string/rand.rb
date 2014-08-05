require 'rmtools/ext/random'

module RMTools
  module String
    
    module RandClassMethods
      
      def rand(*args)
        RMTools.randstr(*args)
      end
      
    end
    
    module Rand
      
      def self.included(string)
        string.__send__ :extend, RandClassMethods
      end
      
      def rand(chsize=1)
        self[Kernel.rand(size*chsize), chsize]
      end

      def randsubstr(chsize=1)
        (a = Kernel.rand(size*chsize)) > (b = Kernel.rand(size*chsize)) ? self[b..a] : self[a..b]
      end

      def randsample(qty=Kernel.rand(size))
        split('').randsample(qty)
      end
      
    end
    
  end
end