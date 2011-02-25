# encoding: utf-8
require 'active_support/core_ext/hash'

class Hash
  alias :>> :reverse_merge!
  
  def +(other_hash)
    merge(other_hash || {})
  end
  
  def unify_keys
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
  
  def max_by_key; [(m = keys.max), self[m]] end
  
  def min_by_key; [(m = keys.min), self[m]] end
  
  def max_by_value; [(m = values.max), self[m]] end
  
  def min_by_value; [(m = values.min), self[m]] end
  
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