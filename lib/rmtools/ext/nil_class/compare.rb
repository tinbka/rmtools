module RMTools
  module NilClass
    module Compare
      
      def <=>(obj)
        obj.nil? ? 0 : -1
      end
      
      def < obj; !obj.nil? end
      def <= obj; true or obj == true end
      def > obj; false end
      def >= obj; obj.nil? or obj == true end
      
    end
  end
end