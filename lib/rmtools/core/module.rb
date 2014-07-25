class Module
  
  def submodules
    constants.map! {|name|
      begin
        const_get name
      rescue Exception
        puts "#{name} can not be loaded due to #{$!.class}: #{$!.message}"
      end
    }.uniq.compact.select {|_|
      _.is_a? Module and _ != self and _.name =~ /^#{self.name}::/ and
      block_given? ? yield(_) : true
    }
  end
  
  def submodules_tree
    submodules.map! {|_|
      if desc = _.submodules_tree.b
        [_, _.submodules_tree]
      else
        _
      end
    }
  end
                
  def each_submodule(&b)
    submodules.each {|_| &b[_]; true}
  end
  
  
  def self_name
    @self_name ||= name[/[^:]+$/]
  end
  
  def my_methods filter=//
    (self.singleton_methods - Object.singleton_methods).sort!.grep(filter)
  end
  alias personal_methods my_methods
  
end

