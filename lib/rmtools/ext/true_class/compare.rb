module RMTools
  module TrueClass
    module Compare
      
      def to_i; 1 end
      
      def <=>(obj)
        case obj
          when nil, false then 1
          when self then 0
          else -1
        end
      end
      
      def < obj; !!obj end
      def <= obj; !!obj or obj == true end
      def > obj; !obj end
      def >= obj; !obj or obj == true end
      
    end
  end
end