module RMTools
  module Object
    module Methods
      
      def my_methods filter=//
        (self.public_methods - Object.public_instance_methods).sort!.grep(filter)
      end
      
      def personal_methods filter=//
        (self.public_methods - self.class.superclass.public_instance_methods).sort!.grep(filter)
      end
      
    end
  end
end