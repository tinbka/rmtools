# encoding: utf-8
class LimitedString < String
  attr_reader :len
  __init__
  
  def initialize str="", len=100
    @len = len
    super str
  end
  
  def inspect
    @len ||= 100
    size > @len ? String.new(self[0...@len]+"…").inspect : super
  end
  
end
  
