# encoding: utf-8
require 'active_support/core_ext/module/remove_method'

class Module
  
  # rewrite of active suport method to not initialize significant part of NameErrors
  def remove_possible_method(method)
    if method_defined? method
      begin remove_method method
      rescue NameError
      end
    end
  end
  
  def children
    constants.map! {|c| module_eval c}.find_all {|c| c.kinda Module rescue()}
  end
                
  def each_child
    constants.map! {|c| module_eval c}.each {|c| yield c if c.kinda Module}
    constants
  end
  
  def self_name
    @self_name ||= name.match[/[^:]+$/]
  end
  
  def my_methods filter=//
    self.singleton_methods.sort!.grep(filter)
  end
  alias personal_methods my_methods
  
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

