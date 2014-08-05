module RMTools
  module Sugar
    module Case
      
      def self.extended(ary)
        ary.class_eval {
          alias orig_casecmp ===
          protected :orig_casecmp
          
          # making multiple (and even nested) pattern matching possible:
          # a, b = '3', '10'
          # case [a, b]
          #   when [Integer, Integer]; a+b
          #   when [/\d/, '10']; '%*d'%[a, b]
          #   ...
          # end
          #
          # symbol :~ stands for Object
          #
          # [Numeric, Hash, [String]] === [ 404, {}, ['Page Not Found'] ] # => true
          # [Numeric, Hash, Array] === [ 404, {}, ['Page Not Found'] ] # => true
          # [Numeric, Hash, [Time]] === [ 404, {}, ['Page Not Found'] ] # => false
          # [Numeric, Hash] === [ 404, {}, ['Page Not Found'] ] # => false
          def ===(obj)
            if obj.is_a?(Array)
              obj.size == size and each_with_index.none? {|e, i| !(e == :~ or e === obj[i])}
            else
              super
            end
          end
        }
      end
      
    end
  end
end