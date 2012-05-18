# encoding: utf-8
# {obj.b -> self or false} with python logic
# Since 2.3.8 active_support has analogue: #presence

class Object
  def b; self end
end
class Numeric
  def b; !zero? && self end
end
class String
  def b; !empty? && self end
end
class Proc
  def b; (self != NULL) && self end
end
class NilClass
  def b; false end
end
module Enumerable
  def b; !empty? && self end
end