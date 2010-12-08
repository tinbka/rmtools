# encoding: utf-8
class Array

  def avg
    sum.to_f/size
  end
  
  def scale(top)
    case top
      when Numeric; ratio = max.to_f/top
      when Array; ratio = zip(top).map {|a,b| b ? a.to_f/b : 0}.max
      else raise TypeError, "number or array of numbers expceted, #{top.class} given"
    end
    map {|e| e/ratio}
  end
  
  def sorted_uniq_by(&block) 
    uniq_by(&block).sort_by(&block)
  end
      
  def recursive_find(&b)
    res = nil
    each {|e|
      return e if b[e]
      if e.resto :recursive_find
        res = e.recursive_find(&b)
        return res if res
      end
    }
    res
  end
      
  def recursive_find_all(&b)
    res = []
    each {|e|
      res << e if b[e]
      if e.resto :recursive_find
        res.concat e.recursive_find_all(&b)
      end
    }
    res.uniq
  end
  
  def set(value, &block)
    return unless e = find(&block)
    self[index(e)] = value
  end
  
  def set_all(value, &block)
    find_all(&block).each {|e| self[index(e)] = value}
  end
  
  def indice(&block)
    return unless e = find(&block)
    index(e)
  end
  alias :pos :indice
  
  def indices(&block)
    i = nil
    find_all(&block).map {|e|
      i = i ?
        self[i+1..-1].index(e) + i + 1 :
        index(e)
    }
  end
  
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
    len = int.to_i
    return [self] if len <= 0
    arr = dup
    clear
    while arr.size > 0
      self << arr.slice!(0, len)
    end
    self
  end
  
  def to_dict
    newhash = {}
    list = dup
    list.each {|gr|
      desc = gr.shift      
      gr.each {|ex| newhash[ex] = desc}
    }
    newhash
  end
  
  def compile_int(base=10)
    int = 0
    pos = size
    each {|i| int += base**(pos -= 1) * i}
    int
  end
  
  def uniq?
    uniq == self
  end  
  
  def odds
    newarr = []
    each_with_index {|e, i| newarr << e if i%2 == 1}
    newarr
  end
  
  def evens
    newarr = []
    each_with_index {|e, i| newarr << e if i%2 == 0}
    newarr
  end
  
  def map_hash &b
    Hash[map(&b)]
  end
  
  def flatmap &b
    ary = []
    each {|e| ary.concat yield e}
    ary
  end
  
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
  def ===(obj)
    return true if casecmp(obj) 
    !!(if obj.kinda(Array) and obj.size == size
          each_with_index {|e, i| e == :_ or e === obj[i] or return false}
        end)
  end
    
  def sum(identity=0, &b) foldl(:+, &b) || identity end

  # should override slower active support's method
  def group_by(&b) count :group, &b end

if RUBY_VERSION < "1.8.7"
  def map_with_index
    a = []
    each_with_index {|e, i| a << yield(e, i)}
    a
  end
else
  def map_with_index(&block)
    each_with_index.map(&block)
  end
end

if !defined? RMTools::Iterators
  alias :throw_no :method_missing
  RMTools::Iterators = %r{(#{(%w{select reject partition find_all find sum foldr min max flatmap}+instance_methods.grep(/_by$/))*'|'})_([\w\d\_]+[!?]?)}
  
  def method_missing(method, *args, &block)
    if match = (meth = method.to_s).match(RMTools::Iterators)
      iterator, meth = match[1..2]
      meth = meth.to_sym
      return send(iterator) {|i| i.__send__ meth, *args, &block}
    elsif meth.sub!(/sses([!?]?)$/, 'ss\1') or meth.sub!(/ies([!?]?)$/, 'y\1') or meth.sub!(/s([!?]?)$/, '\1')
      return map {|i| i.__send__ meth.to_sym, *args, &block}
    else
      throw_no method
    end
  rescue NoMethodError
    throw_no method
  end
end
  
end