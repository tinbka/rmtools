# encoding: utf-8
require 'active_support/core_ext/array'
RMTools::require 'functional/fold'

class Array

  # arithmetics
  def avg
    sum.to_f/size
  end
  
  # for use with iterators
  def avg_by(&b)
    sum(&b).to_f/size
  end
  
  def scale(top)
    case top
      when Numeric; ratio = max.to_f/top
      when Array; ratio = zip(top).map {|a,b| b ? a.to_f/b : 0}.max
      else raise TypeError, "number or array of numbers expected, #{top.class} given"
    end
    map {|e| e/ratio}
  end
  
  
  # setters/getters
  def set_where(value, &block)
    return unless e = find(&block)
    self[index(e)] = value
  end
  
  def set_all_where(value, &block)
    select(&block).each {|e| self[index(e)] = value}
  end
  
  def indice_where(&block)
    return unless e = find(&block)
    index(e)
  end
  alias :pos :indice_where
  
  def indices_where(&block)
    i = nil
    find_all(&block).map {|e|
      i = i ?
        self[i+1..-1].index(e) + i + 1 :
        index(e)
    }
  end
  
  
  # splitters
  def div(int, to_int_parts=nil)
    len = int.to_i
    return [self] if len <= 0
    arr = dup
    newarr = []
    while arr.size > 0
      newarr << arr.slice!(0, len)
    end
    newarr
  end
  
  def div!(int, to_int_parts=nil)
    replace(div(int, to_int_parts))
  end
  
  
  # selectors
  def sorted_uniq_by(&block) 
    uniq_by(&block).sort_by(&block)
  end
  
  def odds
    values_at(*(0...size).odds)
  end
  
  def evens
    values_at(*(0...size).evens)
  end
  
  # conditional
  def uniq?
    uniq == self
  end  
  
  def every?
    !find {|e| !yield(e)}
  end
  
  # concatenation  
  # analogue to String#>>
  def >>(ary)
    ary.replace(self + ary)
  end
  
  
  
  alias :casecmp :===
  # making multiple pattern matching possible:
  # a, b = '3', '10'
  # case [a, b]
  #   when [Integer, Integer]; a+b
  #   when [/\d/, '10']; '%*d'%[a, b]
  #   ...
  # end
  #
  # symbol :~ stands for Object
  def ===(obj)
    return true if casecmp(obj) 
    !!(obj.kinda(Array) and obj.size == size and 
        each_with_index {|e, i| e == :~ or e === obj[i] or return false})
  end
  
  
  
  
  def map_hash(&b)
    Hash[map(&b)]
  end

  def map_with_index(&block)
    each_with_index.map(&block)
  end
    
    
    
    
  # mapreduce
  def sum(identity=0, &b) foldl(:+, &b) || identity end
  
  # fastering activesupport's method
  def group_by(&b) count(:group, &b) end
  
  
  
  
  # rightmost #find
  def rfind
    reverse_each {|e| return e if yield e}
    nil
  end
  
end