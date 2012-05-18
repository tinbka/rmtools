# encoding: utf-8
class Class
  
  # define python-style initializer
  def __init__
    modname, classname = name.match(/^(?:(.+)::)?([^:]+)$/)[1..2]
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
  
  # differs with #ancestors in that it doesn't show included modules
  def superclasses
    superclass ? superclass.unfold(lambda {|c|!c}) {|c| [c.superclass, c]} : []
  end
  
end

require 'set'
[Hash, Array, Set, Regexp, File, Dir, Range, Class, Module].each {|klass| klass.__init__}