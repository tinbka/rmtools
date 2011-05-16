# encoding: utf-8
class Object
  
  def is klass
    if Array === klass
      instance_of?(Array) && self[0].instance_of?(klass[0])
    else instance_of? klass
    end
  end
  
  def kinda klass
    if Array === klass
      kind_of?(Array) && self[0].kind_of?(klass[0])
    else kind_of? klass
    end
  end
  
  def my_methods filter=//
    (self.public_methods - Object.public_instance_methods).sort!.grep(filter)
  end
  
  def personal_methods filter=//
    (self.public_methods - self.class.superclass.public_instance_methods).sort!.grep(filter)
  end
  
  def my_methods_with params
    m = my_methods
    params.each {|p,val| m.reject! {|_| ''.method(_).send(p) != val}}
    m
  end
  
  def personal_methods_with params
    m = personal_methods
    params.each {|p,val| m.reject! {|_| ''.method(_).send(p) != val}}
    m
  end
  
  def readable_variables
    public_methods.to_ss & instance_variables.map {|v|v[1..-1]}
  end
  
  def load_from(obj)
    readable_variables.each {|v| instance_variable_set("@#{v}", obj.instance_variable_get("@#{v}"))}
    self
  end
  
  def in(*container)
    container.size == 1 ? container[0].include?(self) : container.include?(self)
  end
  
end
