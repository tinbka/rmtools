module RMTools
  module Class
    module Methods
      
      def personal_methods filter=//
        (self.singleton_methods - self.superclass.singleton_methods).sort!.grep(filter)
      end
      
      def my_instance_methods filter=//
        (self.public_instance_methods - Object.public_instance_methods).sort!.grep(filter)
      end
      
      def personal_instance_methods filter=//
        (self.public_instance_methods - self.superclass.public_instance_methods).sort!.grep(filter)
      end
      
    end
  end
end