# encoding: utf-8
class Object

  # @ breaker must be callable that returns true value if that's it
  # @ &splitter must return a pair
  def unfold(breaker=lambda{|x|x.b}, &splitter)
    obj, container = self, []
    until breaker.call obj
      obj, next_element = splitter[obj]
      container.unshift next_element
    end
    container
  end
  
end