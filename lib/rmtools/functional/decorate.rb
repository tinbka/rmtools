# Emulate python's @-operator
# Consider as proof of concept since there is alias_method_chain
# that rubyists used to use for decorating
class Module
  
private
  #   example:
  #
  #   def divide_ten_by x
  #       10 / x
  #   end
  #
  #   def maybe(*args)
  #       yield *args rescue(puts $!) 
  #   end
  #    ...
  #  
  #   decorate :divide_ten_by, :maybe  #  =>
  #   def divide_ten_by x
  #       10 / x rescue(puts $!)
  #   end
  def decorate f1, f2
    f1_clone = f1.to_s.dup
    f1_clone.bump! '_' while private_method_defined? f1_clone.to_sym
    class_eval(<<-EVAL, __FILE__, __LINE__+1
      alias #{f1_clone} #{f1}
      private :#{f1_clone}
      def #{f1}(*args) #{f2}(*args, &method(:#{f1_clone})) end
    EVAL
    )
  end
  
  #   some FP, example:
  #
  #   def divide_ten_by x
  #       10 / x
  #   end
  #
  #   def maybe
  #       lambda {|*args| yield *args rescue(puts $!)} 
  #   end
  #    ...
  #  
  #   decorated_fof :divide_ten_by, :maybe  #  =>
  #   def divide_ten_by
  #       lambda {|x| 10 / x rescue(puts $!)}
  #   end
  def decorated_fof f1, f2
    f1_clone = f1.to_s.dup
    f1_clone.bump! '_' while private_method_defined? f1_clone
    class_eval(<<-EVAL, __FILE__, __LINE__+1
      alias #{f1_clone} #{f1}
      private :#{f1_clone}
      def #{f1}() #{f2}(&method(:#{f1_clone})) end
    EVAL
    )
  end
  
end