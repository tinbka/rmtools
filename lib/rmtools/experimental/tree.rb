# encoding: utf-8
class Array
  
	def to_tree(set_keys=false)
		ary = Tree.new dup
		ary.set_keys! if set_keys
		ary
	end
  
  protected
    def set_keys!(i=-1)
      each {|e| Array === e && e.unshift(i+=1).set_keys!}
    end
  
end

module RMTools

  class Tree < Array
    
    def self.from(*obj) new(*obj) end
    
    def initialize(obj, to_ary_method=nil)
      super(to_ary_method ? recurse_build(obj, to_ary_method) : obj.to_a)
    end
    
    def recurse_build(obj, to_ary_method)
      to_ary_method = [to_ary_method] unless Array === to_ary_method
      if to_ary_method = to_ary_method.find {|m| obj.respond_to?(m) && Array === (ary = obj.send m) && ary.size > 0} 
        obj.send(to_ary_method).map {|branch| 
          [branch, recurse_build(branch, to_ary_method)]
        }
      else
        [self]
      end
    end
    
    def trace_leaf(a, c, cont=[])
      return unless Array === a
      return (a[0] == c && cont) if a.size == 1
      y = nil
      a[1..-1].each_with_index.find {|_, i|
          y = trace_leaf(_, c, cont+[[a[0], i]])
      }; y
    end

    def trace_branch(a, c, cont=[])
      return unless Array === a
      return cont if a[0] == c
      y = nil
      a[1..-1].each_with_index.find {|_, i|
          y = trace_branch(_, c, cont+[[a[0], i]])
      }; y
    end
        
    def leaves
      y=[]
      each {|_| Array === node && (node.size>1 ? y.concat(node.leaves) : y.concat(node))}
      y
    end

    def get_branch_by_key(a, key, value)
      return unless Array === a
      return a if a[0][key] == value
      y = nil
      a[1..-1].find {|record| y = get_branch_by_key(record, key, value)}
      y
    end
    
  end

end