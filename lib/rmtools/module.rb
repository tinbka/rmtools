# encoding: utf-8
class Module # :nodoc:
                
  def children
    constants.map! {|c| module_eval c}.find_all {|c| c.kinda Module rescue()}
  end
                
  def each_child
    constants.map! {|c| module_eval c}.each {|c| yield c if c.kinda Module}
    constants
  end
  
  def self_name
    @self_name ||= name.rsplit('::', 2)[1] || name
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
    f1_clone.bump! '_' while method_defined? f1_clone.to_sym
    class_eval do
      alias :"#{f1_clone}" :"#{f1}"
      define_method(f1) {|*args| send(f2, *args, &method(f1_clone))}
    end
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
    f1_clone.bump! '_' while method_defined? f1_clone
    class_eval do
      alias :"#{f1_clone}" :"#{f1}"
      define_method(f1) {send(f2, &method(f1_clone))}
    end
  end
  
end

class Class
  
  # define python-like initializer form
  def __init__
    modname, classname = name.rsplit('::', 2)
    classname ||= modname
    mod = '::'.in(name) ? eval(modname) : RMTools
    mod.module_eval "def #{classname} *args; #{name}.new *args end
                  module_function :#{classname}"
    if mod != RMTools
      mod.each_child {|c| c.class_eval "include #{mod}; extend #{mod}" if !c.in c.children}
    end
  end 
  
  def method_proxy *vars
    buffered_missing = instance_methods.grep(/method_missing/).sort.last || 'method_missing'
    # next arg overrides previous
    vars.each {|v|
      class_eval "
      alias #{buffered_missing.bump! '_'} method_missing
      def method_missing *args, &block
        #{v}.send *args, &block
      rescue NoMethodError
        #{buffered_missing} *args, &block
      end"
    }
  end
  
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