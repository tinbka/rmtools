module RMTools
  module Proc
    
    module Constants
      NULL = lambda {|*x|} unless defined? Proc::NULL
      TRUE = lambda {|*x| true} unless defined? Proc::TRUE
      FALSE = lambda {|*x| false} unless defined? Proc::FALSE
      SELF = lambda {|x| x} unless defined? Proc::SELF
    end
    
    module ClassMethods
      
      def self.extended(proc)
        proc.class_eval {
          include RMTools::Proc::Constants
          attr_accessor :string
        }
      end
      
      def eval string, binding=nil
        (proc = (binding || Kernel).eval "proc {#{string}}").string = string
        proc
      end
      
      def self; Proc::SELF end
      def noop; Proc::NULL end
      def true; Proc::TRUE end
      def false; Proc::FALSE end
      
    end
    
  end
end