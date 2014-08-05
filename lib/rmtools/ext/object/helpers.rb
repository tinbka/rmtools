module RMTools
  module Object
    module Helpers
      
      # def result_of_hard_calculation
      #   ifndef {... hard_calculation ...}
      # end
      # ==
      # def result_of_hard_calculation
      #   if defined? @result_of_hard_calculation
      #     return @result_of_hard_calculation
      #   else
      #     ... hard_calculation
      #     res = ...
      #     @result_of_hard_calculation = res
      #   end
      # end
      def ifndef(ivar=caller(1)[0].parse(:caller).func)
        ivar = :"@#{ivar}"
        return instance_variable_get ivar if instance_variable_defined? ivar
        instance_variable_set ivar, yield 
      end
      
      # def result_of_hard_calculation
      #   ifnull {... hard_calculation ...}
      # end
      # ==
      # def result_of_hard_calculation
      #   if !@result_of_hard_calculation.nil?
      #     return @result_of_hard_calculation
      #   else
      #     ... hard_calculation
      #     res = ...
      #     @result_of_hard_calculation = res
      #   end
      # end
      def ifnull(ivar=caller(1)[0].parse(:caller).func)
        ivar = :"@#{ivar}"
        val = instance_variable_get(ivar)
        return val unless val.nil?
        instance_variable_set ivar, yield 
      end
      
      
      # Instead of my simple implementation
      # use that full-featured of ActiveSupport.
      # Method has been remained for back-compatibility.
      def urlencode(key_or_namespace=nil)
        to_query(key_or_namespace)
      end
  
  
      # Not for primary use. Method with the same name as IV
      # may be written other than by attr_reader/attr_writer
      def readable_variables
        public_methods.to_ss & instance_variables.map {|v|v[1..-1]}
      end
  
      def writable_variables
        public_methods.grep(/=$/).map {|m| m.to_s[0..-2]} & instance_variables.map {|v| v[1..-1]}
      end
      
      def load_from(obj)
        readable_variables.each {|v| instance_variable_set("@#{v}", obj.instance_variable_get("@#{v}"))}
        self
      end
  
  
      # Method has been remained for back-compatibility.
      def in(container)
        in?(container)
      end
      
    end
  end
end