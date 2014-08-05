# encoding: utf-8
class Proc
  NULL = lambda {|*x|} unless defined? Proc::NULL
  TRUE = lambda {|*x| true} unless defined? Proc::TRUE
  FALSE = lambda {|*x| false} unless defined? Proc::FALSE
  SELF = lambda {|x| x} unless defined? Proc::SELF
  attr_accessor :string
  
  def when
    Thread.new do
      sleep 0.001 until yield
      call
    end
  end
  
  class << self
    
    def eval string, binding=nil
      (proc = (binding || Kernel).eval "proc {#{string}}").string = string
      proc
    end
    
    def self; SELF end
    def noop; NULL end
    def true; TRUE end
    def false; FALSE end
  end
  
  if RUBY_VERSION < '1.9'
    def source_location; to_s.match(/([^@]+):(\d+)>$/)[1..2] end
  end
  
end