# encoding: utf-8
class Proc
  NULL = lambda {} unless defined? Proc::NULL
  TRUE = lambda {true} unless defined? Proc::TRUE
  FALSE = lambda {false} unless defined? Proc::FALSE
  attr_accessor :string
  
  def when
    Thread.new do
      sleep 0.001 until yield
      call
    end
  end
  
  def self.eval string, binding=nil
    (proc = (binding || Kernel).eval "lambda {#{string}}").string = string
    proc
  end
  
  if RUBY_VERSION < '1.9'
    def source_location; to_s.match(/([^@]+):(\d+)>$/)[1..2] end
  end
  
end