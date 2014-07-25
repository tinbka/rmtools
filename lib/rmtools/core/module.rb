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
    constants.map! {|c| module_eval c.to_s}.find_all {|c| c.kinda Module rescue()}
  end
                
  def each_child
    (cs = constants.map! {|c| module_eval c.to_s}).each {|c| yield c if c.kinda Module}
    cs
  end
  
  def self_name
    @self_name ||= name[/[^:]+$/]
  end
  
  def my_methods filter=//
    (self.singleton_methods - Object.singleton_methods).sort!.grep(filter)
  end
  alias personal_methods my_methods
  
end

