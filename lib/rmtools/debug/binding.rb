# encoding: utf-8
RMTools::require 'debug/logging'
RMTools::require 'debug/present'

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
  
  def report(obj)
    if Array === obj
      obj.map {|s| self.eval "\"#{s.gsub('"'){'\"'}} = \#{(#{s}).inspect}\""} * '; '
    else
      obj.to_s.split(' ').map {|s| self.eval "\"#{s.gsub('"'){'\"'}} = \#{(#{s}).inspect}\""} * '; '
    end
  end
  
  # it's supposed to be called during TDD in an IRB session
  # $__MAIN__ must be `self' or root IRB session, i.e. `main' object
  # def tested_function
  #   blah blah blah
  # rescue => err
  #   binding.start_interaction
  #   raise err
  # end
  def start_interaction(sandbox=true)
    $__env__ = inspect_env
    puts "Caller trace:"
    Kernel.puts RMTools.format_trace(caller(2)).join("\n")
    puts "Environment:"
    $__env__.present
    $__binding__ = self
    if defined? SCRIPT_LINES__ and (file = caller(0)[0].parse(:caller).file) =~ /^\(irb/
      SCRIPT_LINES__["(#{file[1..-2].next_version '#'})"] = []
    end
    
    $__MAIN__.irb$__binding__
    
    if sandbox
      self.eval($__env__.keys.map {|k, v| "#{k} = $__env__[#{k.inspect}]" if k != 'self'} * '; ')
    end
    $__env__ = nil
  end
  
end