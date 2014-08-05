module RMTools
  module Object
    
    ### Until 3.0 I used python logic:  object.b -> {self | false}
    # Since 3.0 if object is considered falseish then #b returns nil
    # It's still compatible with older logic and more convenient,
    # e.g. for compact'ing resulted array.
    # Also, since 3.0 a String containing only space characters
    # is considered falseish.
    # So, now it's analogue of ActiveSupport's #presence
    # with only difference that zero and empty proc
    # are considrered falseish as well.
    module Being
      
      def self.extended(*)
        Object.class_eval {
          def b; self end
            
          class ::Numeric
            def b; !zero? ? self : nil end
          end
            
          class ::String
            def b; self =~ /\S/ ? self : nil end
          end
            
          class ::Proc
            def b; self != Proc::NULL ? self : nil end
          end
            
          class ::FalseClass
            def b; nil end
          end
            
          module ::Enumerable
            def b; !empty? ? self : nil end
          end
        }
      end
    
    end
  end
end