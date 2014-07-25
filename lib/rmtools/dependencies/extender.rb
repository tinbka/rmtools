module RMTools
  module Extender
  private
  
    def acronym!
      ActiveSupport::Inflector.inflections {|i| i.acronym self_name}
    end
    
    def inherit_enum_attribute(name, default)
      unless respond_to? name
        class_attribute name
        if superclass.respond_to? name
          __send__ :"#{name}=", superclass.__send__(name).dup
        else
          __send__ :"#{name}=", default.dup
        end
      end
      unless method_defined? name
        class_eval "def #{name}; self.class.#{name} end"
      end
    end
  
    def inherit_dict_attribute(name, default={})
      inherit_enum_attribute name, default
    end
  
    def inherit_array_attribute(name, default=[])
      inherit_enum_attribute name, default
    end
    
  end
end