# encoding: utf-8
require 'active_support/core_ext/array'
RMTools::require 'functional/fold'

class Array
  # builtin methods overwrite
  # why should we do zillions of cycles just for ensure A | [] = A - [] = A or A & [] = []
  # though - and & should be improved within C-extension to break loop when no items have lost in self
  alias union |
  alias coallition +
  alias subtraction -
  alias intersection &
  private :union, :coallition, :subtraction, :intersection
  
  def |(ary) 
    if empty?
      ary.uniq
    elsif ary.respond_to? :empty? and ary.empty?
      dup
    else union(ary) 
    end
  end
  
  def +(ary) 
    if empty?
      if ary.respond_to? :empty? and ary.empty?
        []
      else ary.dup 
      end
    elsif ary.respond_to? :empty? and ary.empty?
      dup
    else coallition(ary) 
    end
  end
  
  def -(ary) 
    if empty?
      []
    elsif ary.respond_to? :empty? and ary.empty?
      dup
    else subtraction(ary) 
    end
  end
  
  def &(ary) 
    if empty? or (ary.respond_to? :empty? and ary.empty?)
      [] 
    else intersection(ary) 
    end
  end
  
  def ^(ary)
    if empty? or (ary.respond_to? :empty? and ary.empty?)
      [dup, ary.dup]
    elsif self == ary
      [[], []]
    else
      common = intersection ary
      [self - common, ary - common]
    end
  end
  
  alias diff ^
  
  def intersects?(ary)
    (self & ary).any?
  end
  alias :x? :intersects?

  # arithmetics
  def avg
    empty? ? nil : sum.to_f/size
  end
  
  # for use with iterators
  def avg_by(&block)
    empty? ? nil : sum(&block).to_f/size
  end
  
  def scale(top)
    case top
      when Numeric; ratio = max.to_f/top
      when Array; ratio = zip(top).map {|a,b| b ? a.to_f/b : 0}.max
      else raise TypeError, "number or array of numbers expected, #{top.class} given"
    end
    map {|e| e/ratio}
  end
  
  
  # setters/getters/deleters
  def set_where(value, &block)
    each_with_index {|e, i| return self[i] = value if block[e]}
    nil
  end
  
  def set_all_where(value, &block)
    #select(&block).each {|e| self[index(e)] = value} # 3.643
    #each_with_index {|e, i| self[i] = value if block[e]} # 0.240
    # велосипедист, бля
    map! {|e| block[e] ? value : e} # 0.168
  end
  
  def index_where(&block)
    each_with_index {|e, i| return i if block[e]}
    nil
  end
  alias :pos :index_where
  
  def indices_where(&block)
    a = []
    each_with_index {|e, i| a << i if block[e]}
    a
  end
  
  def del_where(&block)
    each_with_index {|e, i| return delete_at i if block[e]}
    nil
  end
  
  def del_all_where(&block)
    reject!(&block)
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
  
  
  # filters  
  def odds
    values_at(*(0...size).odds)
  end
  
  def evens
    values_at(*(0...size).evens)
  end
  
  # conditional
  def every?
    !find {|e| !yield(e)}
  end
  
  def no?
    !find {|e| yield(e)}
  end
  
  # rightmost #find
  def rfind
    reverse_each {|e| return e if yield e}
    nil
  end
  
  # find-by-value filters
  # It's more of a pattern. Use of respective meta-iterators is prefered.
  def find_by(key, value)
    find {|e| e.__send__(key) == value}
  end
  
  # rightmost #find_by
  def rfind_by(key, value)
    reverse_each {|e| return e if e.__send__(key) == value}
    nil
  end
  
  def select_by(key, value)
    select {|e| e.__send__(key) == value}
  end
  
  def reject_by(key, value)
    reject {|e| e.__send__(key) == value}
  end
  
  
  # uniqs
  def uniq?
    uniq == self
  end  
  
  # rightmost #uniq
  def runiq
    reverse.uniq.reverse
  end
  
  # rightmost #uniq_by
  def runiq_by(&block)
    reverse.uniq_by(&block).reverse
  end
  
  # sort / group
  def sorted_uniq_by(&block) 
    uniq_by(&block).sort_by(&block)
  end
  
  # C-function, see it in /ext
  def arrange_by(*args, &block)
    arrange(*args, &block)
  end
  
  def indices_map
    addresses = {}
    (size-1).downto(0) {|i| addresses[self[i]] = i}
    addresses
  end
  alias :addresses :indices_map
  
  def sort_along_by(ary)
    # Condition is relevant for ruby 1.9, I haven't tested it on 1.8 yet
    if size*ary.size > 400
      addresses = ary.indices_map
      sort_by {|e| addresses[yield(e)]}
    else
      sort_by {|e| ary.index yield e}
    end
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
  
  
  
  # enumerating
  def map_with_index(&block)
    each_with_index.map(&block)
  end
    
  def each_two
    _end = size-1
    self[0..-2].each_with_index {|u, i|
      (i+1.._end).each {|j|
        yield u, self[j]
      }
    }
  end
    
    
    
  # mapreduce
  def sum(identity=0, &b) 
    foldl(:+, &b) || identity 
  end
  
  # fastering activesupport's method
  def group_by(&b) 
    arrange(:group, &b) 
  end
  
end