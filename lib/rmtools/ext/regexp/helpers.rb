module RMTools
  module Regexp
    module Helpers
   
      def | re
        Regexp.new(source+'|'+re.source, options | re.options)
      end
      
      def in string
        string =~ self
      end
    
    end
  end
end