module RMTools
  module Array
    module Compare
      
      # extension of instance_of?
      # can compare like this:
      #   [ 404, {}, ['Page Not Found'] ].is [Fixnum, Hash, [String]] # => true
      #   [ 404, {}, ['Page Not Found'] ].is [Fixnum, Hash, Array] # => true
      #   [ 404, {}, ['Page Not Found'] ].is [Fixnum, Hash] # => false
      #   [ 404, {}, ['Page Not Found'] ].is [Numeric, Hash, Array] # => false
      def is(something)
        if something.instance_of?(Array)
          something.size == size and
            each_with_index.none? {|_, i| !_.is something[i]}
        else
          super
        end
      end
      
      # extension of is_a?/kind_of?
      # analogue of #is but uses #kind_of? internally instead of #instance_of?
      # can compare like this:
      #   [ 404, {}, ['Page Not Found'] ].kinda [Numeric, Hash, [String]] # => true
      #   [ 404, {}, ['Page Not Found'] ].kinda [Numeric, Hash, Array] # => true
      #   [ 404, {}, ['Page Not Found'] ].kinda [Numeric, Hash, Set] # => false
      #   [ 404, {}, ['Page Not Found'] ].kinda [Numeric, Hash] # => false
      def kinda(something)
        if something.instance_of?(Array)
          something.size == size and
            each_with_index.none? {|_, i| !_.kinda something[i]}
        else
          super
        end
      end
      
      # Array#=== rewrite lies in rmtools/sugar/
    end
  end
end
      