module RMTools
  module Class
    module Attributes
    private
    
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
end