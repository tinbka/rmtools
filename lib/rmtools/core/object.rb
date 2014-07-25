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
  
  def inspect_instance_variables
    instance_eval {binding().inspect_instance_variables}
  end
  
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
  
  
  
  def deep_clone
    _deep_clone({})
  end

protected
  def _deep_clone(cloning_map)
    return cloning_map[self] if cloning_map.key? self
    cloning_obj = clone
    cloning_map[self] = cloning_obj
    cloning_obj.instance_variables.each do |var|
      val = cloning_obj.instance_variable_get(var)
      begin
        val = val._deep_clone(cloning_map)
      rescue TypeError
        next
      end
      cloning_obj.instance_variable_set(var, val)
    end
    cloning_obj
  end
  
end
