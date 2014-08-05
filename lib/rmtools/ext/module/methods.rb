module RMTools
  module Module
    module Methods
      
      def my_methods filter=//
        (self.singleton_methods - Object.singleton_methods).sort!.grep(filter)
      end
      alias personal_methods my_methods
      
    end
  end
end