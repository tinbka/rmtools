module RMTools
  module Binding
    module Inspect
      
      def inspect_local_variables
        vars = self.eval('local_variables') # ['a', 'b']
        values = self.eval "[#{vars * ','}]" # ["a's value", "b's value"]
        Hash[vars.zip(values)]
      end
      
      def inspect_instance_variables
        vars = self.eval('instance_variables') # ['@a', '@b']
        if vars and vars.any?
          values = self.eval "[#{vars * ','}]" # ["@a's value", "@b's value"]
          Hash[vars.zip(values)]
        else {}
        end
      end
      
      # There is something funny with class variables scope:
      # C.class_eval {binding().eval 'self'}
      # # => C
      # C.class_eval {binding().eval 'class_variable_get :@@attr'}
      # # => :CA_cv
      # C.class_eval {binding().eval '@@attr'}
      # # NameError: uninitialized class variable @@attr in Object
      class Binding
      def inspect_class_variables
        vars = self.eval('(is_a?(Module) ? self : self.class).class_variables') # ['@@a', '@@b']
        if vars and vars.any?
          values = self.eval "{#{vars.map {|v| "'#{v}'=>class_variable_get(:#{v})"} * ','}}" # ["@@a's value", "@@b's value"]
        else {}
        end
      end
      end
      
      def inspect_special_variables
        Hash[self.eval(%[{"self" => self, #{['!', '`', '\'', '&', '~', *(1..9)].map {|lit| %{"$#{lit}" => $#{lit}, }}.join}}]).reject {|k,v| v.nil?}]
      end
      
      def inspect_env
        inspect_local_variables + inspect_instance_variables + inspect_class_variables + inspect_special_variables
      end
      
    end
  end
end