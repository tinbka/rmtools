module RMTools
  module Initializers
  end
  
  module Sugar
    module Initialization
      
      # for description, see rmtools/ext/class/init
      def self.extended(*)
        [Set, Regexp, File, Dir, Range, Class, Module, Thread, Proc].each {|klass| klass.__send__:__init__}
        Object.__send__ :include, Initializers
      end
      
    end
  end
end