module RMTools
  
  # Builtin methods overwrite.
  # Should be included in both Set and Array
  # and excluded if something went wrong.
  #
  # Stop doing zillions of cycles just for ensure that
  #   A | [] = A - [] = A + [] = A
  #   A & [] = []
  # If one of sets is empty, don't do anything.
  module SmarterSetOperators
    
    def self.included(acceptor)
      acceptor.class_eval {
        alias :union :|
        alias :coallition :+
        alias :subtraction :-
        alias :intersection :&
        # :& won't work this way if :intersection will be protected
        protected :union, :coallition, :subtraction
        
        def |(ary) 
          return ary.uniq if empty?
          return uniq if ary.respond_to? :empty? and ary.empty?
          
          union ary
        end
        
        def +(ary) 
          if empty?
            return [] if ary.respond_to? :empty? and ary.empty?
            ary.dup
          end
          return dup if ary.respond_to? :empty? and ary.empty?
          
          coallition ary
        end
        
        def -(ary) 
          return [] if empty?
          return dup if ary.respond_to? :empty? and ary.empty?
          
          subtraction ary
        end
        
        def &(ary) 
          return [] if empty? or (ary.respond_to? :empty? and ary.empty?)
          return ary.intersection self if size < ary.size
          
          intersection ary
        end
      }
    end
    
  end
    
  # Not overwrite. Does not require SmarterSetOperations.
  # Must be included in both Set and Array.
  module SetMethods
        
    def diff(ary)
      return [dup, ary.dup] if empty? or (ary.respond_to? :empty? and ary.empty?)
      return [[], []] if self == ary
      
      common = intersection ary
      [self - common, ary - common]
    end
    
    def intersects?(ary)
      (self & ary).any?
    end
    
    def contains?(ary)
      (ary - self).empty?
    end
    
    def is_subset_of?(ary)
      (self - ary).empty?
    end
    
    def self.included(acceptor)
      acceptor.class_eval {
        alias :^ :diff
        alias :x? :intersects?
        alias :=~ :contains?
      }
    end

  end
  
end