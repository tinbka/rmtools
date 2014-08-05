module RMTools
  module String
    # Hash and Array will not have similar extension
    # because implicit conversion in their cases
    # would have hardly predictable effect
    module Concatenation
      
      def self.extended(string)
        string.class_eval {
          alias :plus :+ 
          private :plus
        
          #   immutable:
          # '123' + 95 # => '12395'
          # '123'.plus 95 # => raise TypeError
          def +(str)
            plus str.to_s
          end
          
          #   mutable:
          # '123' << 95 # => '12395'
          # '123'.concat 95 # => '123_'
          def <<(str)
            concat str.to_s
          end
        }
      end
      
    end
  end
end