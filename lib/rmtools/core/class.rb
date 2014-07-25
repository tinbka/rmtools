# encoding: utf-8
require 'rmtools/core/object'

class Class
  
  def personal_methods filter=//
    (self.singleton_methods - self.superclass.singleton_methods).sort!.grep(filter)
  end
  
  def my_instance_methods filter=//
    (self.public_instance_methods - Object.public_instance_methods).sort!.grep(filter)
  end
  
  def personal_instance_methods filter=//
    (self.public_instance_methods - self.superclass.public_instance_methods).sort!.grep(filter)
  end
  
  # differs with #ancestors in that it doesn't show included modules
  def superclasses
    superclass ? superclass.unfold(lambda {|c|!c}) {|c| [c.superclass, c]} : []
  end
  
  private
  # module Container
  #   class Initialized
  #     __init__
  #   end
  #   Initializers::Initialized() # Container::Initialized.new
  #   Initialized() # Container::Initialized.new
  #
  #   class Inner
  #     Container::Initialized() # Container::Initialized.new
  #     Initialized() # Container::Initialized.new
  #     def init
  #       Container::Initialized() # Container::Initialized.new
  #       Initialized() # Container::Initialized.new
  #     end
  #   end
  # end
  # 
  # class Outer
  #   Container::Initialized() # Container::Initialized.new
  #   Initialized() # NoMethodError
  #   def init
  #     Container::Initialized() # Container::Initialized.new
  #     Initialized() # NoMethodError
  #   end
  # end
  def __init__
    mod = prnt = parent
    if prnt == Object
      mod = RMTools
    end
    
    mod.module_eval "
    module Initializers
      def #{classname} *args, **kw &block
        if kw.empty?
          #{name}.new *args &block
        else
          #{name}.new *args, **kw &block
        end
      end
      module_function :#{classname}
    end"
    
    if prnt != Object
      [prnt, prnt.submodules].flatten.each {|m|
        m.__send__ :include, mod::Initializers
        m.__send__ :extend, mod::Initializers
      }
    end
  end
  
end

require 'set'
[Hash, Set, Regexp, File, Dir, Range, Class, Module, Thread, Proc].each {|klass| klass.class_eval {__init__}}