module RMTools
  module Class
    module Init
    private
      # module Container
      #   class Initialized
      #     __init__
      #   end
      #   Initializers::Initialized() # Container::Initialized.new
      #   Initialized() # Container::Initialized.new
      #
      #   class Inner
      #     Container::Initialized() # Container::Initialized.new
      #     Initialized() # Container::Initialized.new
      #     def init
      #       Container::Initialized() # Container::Initialized.new
      #       Initialized() # Container::Initialized.new
      #     end
      #   end
      # end
      # 
      # class Outer
      #   Container::Initialized() # Container::Initialized.new
      #   Initialized() # NoMethodError
      #   def init
      #     Container::Initialized() # Container::Initialized.new
      #     Initialized() # NoMethodError
      #   end
      # end
      def __init__
        mod = prnt = parent
        if prnt == Object
          mod = RMTools
        end
        
        mod.module_eval "
        module Initializers
          def #{classname} *args, **kw &block
            if kw.empty?
              #{name}.new *args &block
            else
              #{name}.new *args, **kw &block
            end
          end
          module_function :#{classname}
        end"
        
        if prnt != Object
          [prnt, prnt.submodules].flatten.each {|m|
            m.__send__ :include, mod::Initializers
            m.__send__ :extend, mod::Initializers
          }
        end
      end
      
    end
  end
end