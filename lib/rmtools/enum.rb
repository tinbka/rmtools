# encoding: utf-8
module Enumerable
  
  def import(arr, index)
    self[index] = arr[index]
  end
  
  def export(arr, index)
    arr[index] = self[index]
  end

  def foldl(o, m=nil)
    block_given? ?
      reduce(m ? yield(m) : nil) {|m, i| m ? m.send(o, yield(i)) : yield(i)} :
      reduce(m) {|m, i| m ? m.send(o, i) : i}
  end

  def foldr(o, m=nil)
    block_given? ?
      reverse.reduce(m ? yield(m) : nil) {|m, i| m ? yield(i).send(o, m) : yield(i)} :
      reverse.reduce(m) {|m, i| m ? i.send(o, m) : i}
  end
  
if RUBY_VERSION < "1.8.7"
  def xprod(obj, inverse=false)
    size = self.size
    if obj.kinda Array or obj.is Set
      objsize = obj.size
      raise ArgumentError, "can't complement #{self.class} with void container" if objsize == 0
      if size == 1
        case objsize
          when 1 then inverse ? [[obj.first, first]] : [[first, obj.first]]
          else 	           obj.xprod_one first, !inverse
        end
      else
        case objsize
          when 1 then xprod_one   obj.first, inverse
          else	           xprod_many obj, inverse
        end
      end
    else	                 xprod_one   obj, inverse
    end
  end

protected
  def xprod_one(obj, inverse)
    inverse ? map {|te| [obj, te]} : map {|te| [te, obj]} 
  end
  
  def xprod_many(obj, inverse)
    a = []
    inverse ? 
      obj.each {|oe| each {|te| a << [oe, te]}} : 
      each {|te| obj.each {|oe| a << [te, oe]}}
    a
  end
else
  def xprod(obj, inverse=false)
    obj = obj.to_a if obj.is Set
    obj = [obj] if !obj.kinda(Array)
    inverse ? obj.to_a.product(self) : product(obj)
  end
end

end

module ObjectSpace
  extend Enumerable
 
  def self.each(&b) self.each_object(&b) end
 
end

class Object

  # block must return a pair
  def unfold(break_if=lambda{|x|x==0}, &splitter)
    obj, container = self, []
    until begin
        result = splitter[obj]
        container.unshift result[1]
        break_if[result[0]]
      end
      obj = result[0]
    end
    container
  end
  
end
 