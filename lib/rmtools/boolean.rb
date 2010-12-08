# encoding: utf-8
class Numeric
  def b; (self != 0) && self end
end
class String
  def b; !empty? && self end
end
class Proc
  def b; (self != NULL) && self end
end
module Enumerable
  def b; !empty? && self end
end

class TrueClass
  def to_i; 1; end
  def <=>(obj)
    case obj
      when nil, false then 1
      when self then 0
      else -1
    end
  end
  
  def < obj; !!obj end
  def <= obj; !!obj or obj == true end
  def > obj; !obj end
  def >= obj; !obj or obj == true end
end

class FalseClass
  def to_i; 0; end
  def <=>(obj)
    case obj
      when nil then 1
      when self then 0
      else -1
    end
  end
  
  def < obj; !!obj end
  def <= obj; !obj.nil? end
  def > obj; obj.nil? end
  def >= obj; !obj end
end

class NilClass
  def to_i; 0; end
  def <=>(obj)
    obj.nil? ? 0 : -1
  end
  
  def < obj; !obj.nil? end
  def <= obj; true or obj == true end
  def > obj; false end
  def >= obj; obj.nil? or obj == true end
end