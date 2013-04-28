module RMTools

  # It's included into Dir and could also be included into Enumerable
  # Though we don't do latter automatically, because Enumerable as it is overloaded of a bunch of questionable methods
  module ValueTraversal
    
    def preorder_traverse(&b)
      next_level = RMTools::ValueTraversable.new
      to_traversable.each {|e|
        if e.respond_to? :preorder_traverse
          next_level += e
        else
          b[e]
        end
      }
      next_level.preorder_traverse(&b) if next_level.any?
    end
    
    def depth_first_traverse(&b)
      to_traversable.flatten.each &b
    end
    
    def preorder_find(&b)
      next_level = RMTools::ValueTraversable.new
      to_traversable.each {|e|
        if e.respond_to? :preorder_find
          next_level += e
        else
          return e if b[e]
        end
      }
      next_level.preorder_find(&b) if next_level.any?
    end
    
    def depth_first_find(&b)
      to_traversable.each {|e| 
        if v.respond_to? :depth_first_find
          if res = e.depth_first_find(&b)
            return res
          end
        else
          return e if b[e]
        end
      }
      nil
    end
    
    def preorder_select
      res = []; preorder_traverse {|e| res << e if yield(e)}; res
    end  
    
    def depth_first_select
      res = []; depth_first_traverse {|e| res << e if yield(e)}; res
    end  
    
    def depth_first_map(&b)
      to_traversable.map {|e| 
        if e.respond_to? :depth_map
          e.depth_map &b
        else
          b[e]
        end
      }
    end
    
  end

  # Presumptions:
  #   all keys (at least on the same depth) are uniq
  #   values are either enumerable or nothing
  #
  # It's included into Hash
  module KeyValueTraversal
    
    def preorder_traverse(&b)
      next_level = RMTools::KeyValueTraversable.new
      to_traversal.each {|k, v|
        b[k]
        if v.respond_to? :preorder_traverse
          next_level += v
        end
      }
      next_level.preorder_traverse(&b) if next_level.any?
    end
    
    def depth_first_traverse(&b)
      to_traversal.each {|k, v|
        b[k]
        if v.respond_to? :depth_first_traverse
          v.depth_first_traverse &b
        end
      }
    end
    
    def preorder_find(&b)
      next_level = RMTools::KeyValueTraversable.new
      to_traversal.each {|k, v|
        return k if b[k]
        if v.respond_to? :preorder_find
          next_level += v
        end
      }
      next_level.preorder_find(&b) if next_level.any?
    end
    
    def depth_first_find(&b)
      to_traversal.each {|k, v|
        return k if b[k]
        if v.respond_to?(:depth_first_traverse) and res = v.depth_first_traverse(&b)
          return res
        end
      }
      nil
    end
    
    def preorder_select
      res = []; preorder_traverse {|k, v| res << k if yield(k)}; res
    end  
    
    def depth_first_select
      res = []; depth_first_traverse {|k, v| res << k if yield(k)}; res
    end
    
  end
  
  class ValueTraversable < Array
    include ValueTraversal    
    __init__
    
    private
    alias :array_plus :+
    public
    
    def +(enum)
      if Hash === enum
        enum = enum.values
      end
      array_plus enum.to_traversable
    end
    
    def to_traversable
      self
    end
  end
  
  class KeyValueTraversable < Hash
    include KeyValueTraversal    
    __init__
    
    def +(enum)
      if Hash === enum
        merge enum.to_traversable
      else
        values.to_traversable.concat enum.to_traversable
      end
    end
    
    def to_traversable
      self
    end
  end
  
end

