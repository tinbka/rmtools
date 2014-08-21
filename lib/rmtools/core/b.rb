# {obj.b -> self or false} with python logic
# Since 2.3.8 ActiveSupport has similar method: #presence
# Though, #b is obviously more usable due to it's length, 
# and still intuitive: "Boolean", "Being", "to Be"
# Differs from #presence in that String#b do not use #strip for check

class Object
  def b; self end
end

class Numeric
  def b; !zero? && self end
end

if RUBY_VERSION < '2.1'
  class String
    def b; !empty? && self end
  end
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