class Binding
  
  def inspect_local_variables
    vars = self.eval('local_variables') # ['a', 'b']
    values = self.eval "[#{vars * ','}]" # ["a's value", "b's value"]
    Hash[vars.zip(values)]
  end
  
  def inspect_instance_variables
    vars = self.eval('instance_variables') # ['@a', '@b']
    values = self.eval "[#{vars * ','}]" # ["@a's value", "@b's value"]
    Hash[vars.zip(values)]
  end
  
  def inspect_env
    self.eval("{'self' => self}").merge(inspect_local_variables).merge(inspect_instance_variables)
  end
  
  def valid_types(pattern_ary)
    self.eval("[#{self.eval('local_variables')*','}]").valid_types(pattern_ary)
  end
  
end