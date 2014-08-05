module RMTools
  module Sugar
    module Dictation
    
      # hash = {}
      # hash.abc = 123
      # hash # => {"abc"=>123}
      # hash.abc # => 123
      # hash.unknown_function(321) # => raise NoMethodError
      # hash.unknown_function # => nil
      # hash[:def] = 456
      # hash.def # => 456
      #
      # This priority should be stable, because 
      def self.extended(dictable)
        dictable.class_eval {
        
          def method_missing(method, *args)
            str = method.to_s
            if str =~ /=$/
              self[str[0..-2]] = args[0]
            elsif !args.empty? or str =~ /[!?]$/
              super
            else
              a = self[method]
              (a == default) ? self[str] : a
            end
          end
  
          # These methods are deprecated since Ruby 1.8.somewhat,
          # though still defined
          def type
            a = self[:type]
            (a == default) ? self['type'] : a
          end
          
          def id
            a = self[:id]
            (a == default) ? self['id'] : a
          end
          
          def index
            a = self[:index]
            (a == default) ? self['index'] : a
          end
          
        }
      end
      
    end
  end
end