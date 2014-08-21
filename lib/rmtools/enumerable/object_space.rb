# encoding: utf-8
RMTools::require 'enumerable/common'

module ObjectSpace
  extend Enumerable
  class << self
 
    def each(&b) each_object(&b) end
  
    def size() each_object {} end
  
    def find(id=nil)
      if id
        find {|obj| obj.object_id == id} 
      else
        each_object {|obj| return obj if yield obj}
        nil
      end
    end
    alias [] find
    
  end
end