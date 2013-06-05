# encoding: utf-8
module RMTools
  
  # Builtin methods overwrite.
  # Why should we do zillions of cycles just for ensure
  # `A | [] = A - [] = A or A & [] = []`
  # ?
  # Though #- and #& should be improved within C-extension to break loop when no items have had lost in self (Or not? Don't remember what I had on my mind while I've being writing this)
  module SmarterSetOps
    
    def self.included(acceptor)
      acceptor.class_eval {
        alias :union :|
        alias :coallition :+
        alias :subtraction :-
        alias :intersection :&
        protected :union, :coallition, :subtraction, :intersection
      }
    end
    
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
      return ary.intersection self if size > ary.size
      
      intersection ary
    end
    
    def ^(ary)
      return [dup, ary.dup] if empty? or (ary.respond_to? :empty? and ary.empty?)
      return [[], []] if self == ary
      
      common = intersection ary
      [self - common, ary - common]
    end
    
    alias diff ^
    
    def intersects?(ary)
      (self & ary).any?
    end
    alias :x? :intersects?
  
  end
end