# encoding: utf-8
module Enumerable
  
  def to_traversable
    RMTools::ValueTraversable(to_a)
  end
  
  def import(arr, index)
    self[index] = arr[index]
  end
  
  def export(arr, index)
    arr[index] = self[index]
  end
  
  def xprod(obj, inverse=false)
    obj = obj.to_a if obj.is_a? Set
    obj = [obj] unless obj.is_a? Array
    inverse ? obj.to_a.product(self) : product(obj)
  end
      
  def recursive_find(&b)
    res = nil
    to_a.each {|e|
      return e if b[e]
      if e.resto :recursive_find and res = e.recursive_find(&b)
        return res
      end
    }
    res
  end
      
  def recursive_select(&b)
    res = []
    to_a.each {|e|
      res << e if b[e]
      if e.resto :recursive_find
        res.concat e.recursive_find_all(&b)
      end
    }
    res.uniq
  end
  
  unless method_defined? :map_hash
  def map_hash(&block)
    Hash[map(&block)]
  end
  end
  
  def present
    to_a.present
  end
  
  def +(array)
    to_a + array.to_a
  end
    
  def =~(item_or_pattern)
    include? item_or_pattern
  end

  def threadify(threads=4, &block)
    RMTools::threadify(self, threads, &block)
  end
  
  def truth_map
    to_a.map_hash {|i| [i, true]}
  end

end