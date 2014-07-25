module RMTools
  module Object
    module Compare
      
      # extension of instance_of?
      # overwritten by Array::Compare
      def is(something)
        !something.instance_of?(Array) and instance_of? something
      end
      
      # extension of is_a?/kind_of?
      # overwritten by Array::Compare
      # although this name sux, it's used too often in other my gems >_>
      def kinda klass
        !something.instance_of?(Array) and kind_of? something
      end
    
    end
  end
end