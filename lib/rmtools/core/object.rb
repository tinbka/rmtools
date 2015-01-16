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
  
  
  # def hard_method(args)
  #   ... hard_calculation ...
  # end
  #
  # object.cached(:hard_method, *args1)
  # > ... hard calculation ...
  # => result with args1
  # object.cached(:hard_method, *args1)
  # => instant result with args1
  # object.cached?(:hard_method, *args2)
  # => false
  # object.cached(:hard_method, *args2)
  # > ... hard calculation ...
  # => result with args2
  # object.cached?(:hard_method, *args2)
  # => true
  # object.clear_cache(:hard_method, *args1)
  # => result with args1
  # object.cached?(:hard_method, *args1)
  # => false
  # object.cached(:hard_method, *args1)
  # > ... hard calculation ...
  # => result with args1
  # object.cached(:hard_method, *args2)
  # => instant result with args2
  # object.clear_cache(:hard_method)
  # => {args1 => result with args1, args2 => result with args2}
  # [object.cached?(:hard_method, *args1), object.cached?(:hard_method, *args2)]
  # => [false, false]
  def cached(method, *args)
    ((@__method_cache__ ||= {})[method.to_sym] ||= {})[args] ||= __send__ method, *args
  end
  
  def clear_cache(method, *args)
    if @__method_cache__
      if args.empty?
        @__method_cache__.delete method.to_sym
      elsif method_cache = @__method_cache__[method.to_sym]
        method_cache.delete args
      end
    end
  end
  
  def cached?(method, *args)
    ((@__method_cache__ ||= {})[method.to_sym] ||= {}).include? args
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
