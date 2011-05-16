# encoding: utf-8
module Enumerable
  
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
      
  def recursive_find_all(&b)
    res = []
    to_a.each {|e|
      res << e if b[e]
      if e.resto :recursive_find
        res.concat e.recursive_find_all(&b)
      end
    }
    res.uniq
  end
  
  def present
    to_a.present
  end
  
  def +(array)
    to_a + array.to_a
  end

end