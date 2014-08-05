module RMTools
  module Console
    module Inspect
      
      def inspect_instance_variables
        instance_eval {binding().inspect_instance_variables}
      end
      
      def inspect_class_variables
        instance_eval {binding().inspect_class_variables}
      end
      
    end
  end
end