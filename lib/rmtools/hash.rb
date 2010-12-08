# encoding: utf-8
class Hash
  
  def +(other_hash)
    merge(other_hash || {})
  end
  
  def concat(other_hash)
    merge!(other_hash || {})
  end
  
  def unify_strs
    each {|k, v|
      if k.is String
        sk = k.to_sym
        self[sk] = v if !self[sk]
      elsif k.is Symbol
        sk = k.to_s
        self[sk] = v if !self[sk]
      end
    }
  end
  
  def max; [(m = keys.max), self[m]] end
  
  def min; [(m = keys.min), self[m]] end
  
  # should be overriden by extension maps
  def map2
    h = {}
    each {|k, v| h[k] = yield(k,v)}
    h
  end
  
  def map!
    each {|k, v| self[k] = yield(k,v)}
    self
  end

end