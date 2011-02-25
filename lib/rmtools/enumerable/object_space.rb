# encoding: utf-8
RMTools::require 'enumerable/common'

module ObjectSpace
  extend Enumerable
 
  def self.each(&b) each_object(&b) end
  
  def self.size; each_object {} end
  
  def self.find(id=nil)
    if id
      find {|obj| obj.object_id == id} 
    else
      each_object {|obj| return obj if yield obj}
      nil
    end
  end
 
end