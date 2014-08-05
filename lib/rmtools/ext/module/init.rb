module RMTools
  module Module
    module Init
    private
    
      # see rmtools/class/init
      def __init__
        descendants_tree.flatten.uniq.each {|m| m.__send__:__init__ if m.is_a? Class}
      end
      
    end
  end
end