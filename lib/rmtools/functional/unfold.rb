# encoding: utf-8
class Object

  # &splitter must return a pair
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