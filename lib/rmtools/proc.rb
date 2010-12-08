# encoding: utf-8
class Proc
  include RMTools
  NULL = lambda {} unless defined? Proc::NULL
  attr_accessor :string
  
  def inspect
    "#{str=to_s}: #{@string ? Painter.green(@string) : "\n"+highlighted_line(*str.match(/([^@]+):(\d+)>$/)[1..2])}"
  end
  
  def self.when condition
    if condition.is String
      sleep 0.001 until eval condition
    else
      sleep 0.001 until condition.call
    end
    yield
  end
  
  def self.eval string, binding=nil
    (proc = (binding || Kernel).eval "lambda {#{string}}").string = string
    proc
  end
  
end