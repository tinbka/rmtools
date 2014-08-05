module RMTools
  module Module
    module Helpers
   
      def self_name
        @self_name ||= name[/[^:]+$/]
      end

      def acronym!
        ActiveSupport::Inflector.inflections {|i| i.acronym self_name}
      end
    
    end
  end
end