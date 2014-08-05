module RMTools
  module FalseClass
    module Compare
      
      def to_i; 0 end
      
      def <=>(obj)
        case obj
          when nil then 1
          when self then 0
          else -1
        end
      end
      
      def < obj; !!obj end
      def <= obj; !obj.nil? end
      def > obj; obj.nil? end
      def >= obj; !obj end
      
    end
  end
end