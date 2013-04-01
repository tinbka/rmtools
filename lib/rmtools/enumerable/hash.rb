# encoding: utf-8
require 'active_support/core_ext/hash'
RMTools::require 'enumerable/traversal'

class Hash
  include RMTools::KeyValueTraversal
  alias :>> :reverse_merge!
  
  def to_traversable
    RMTools::KeyValueTraversable.new(self)
  end
  
  def +(other_hash)
    merge(other_hash || {})
  end
  
if RUBY_VERSION >= '1.9.2'
  def unify_keys
    keys.each {|k|
      case k
      when String
        sk = k.to_sym
        self[sk] = self[k] if !self[sk]
      when Symbol, Numeric
        sk = k.to_s
        self[sk] = self[k] if !self[sk]
      end
    }
    self
  end
else
  def unify_keys
    each {|k, v|
      case k
      when String
        sk = k.to_sym
        self[sk] = v if !self[sk]
      when Symbol, Numeric
        sk = k.to_s
        self[sk] = v if !self[sk]
      end
    }
  end
end

  def any?
    !empty?
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