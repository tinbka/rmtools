# encoding: utf-8
RMTools::require 'debug/highlight'
RMTools::require 'debug/logging'

module RMTools

	# Python-like traceback for exceptions; uses ANSI coloring.
  # In case of any low-level ruby error it may hang up interpreter
  # (although you must have done creepy things for that). If you find 
  # interpreter in hanging up, require 'rmtools_notrace' instead of 'rmtools'
  # or run "Exception.trace_format false" right after require
  #
  # 1:0> def divbyzero
  # 2:1< 10/0 end
  # => nil
  # 3:0> divbyzero
  # ZeroDivisionError: divided by 0
  #        from (irb):2:in `divbyzero' <- `/'
  #   >>  10/0 end
  #        from (irb):3
  #   >>  divbyzero
  def format_trace(a)
    bt, calls, i = [], [], 0
  #  $log.info 'a.size', binding
    m = a[0].parse:caller
    while i < a.size
  #    $log.info 'i a[i]', binding
      m2 = a[i+1] && a[i+1].parse(:caller)
  #    $log.info 'm m2', binding
  #    $log.info 'm.func [m.path,m.line]==[m2.path,m2.line]', binding if m and m2
  #    $log.info 'm.path m.line a[i]', binding if m
  #    $log.info RMTools.highlighted_line(m.path, m.line) if m
      if m and m.func and m2 and [m.path, m.line] == [m2.path, m2.line]
        calls << " -> `#{m.func}'"
      elsif m and m.line != 0 and line = RMTools.highlighted_line(m.path, m.line)
        bt << "#{a[i]}#{calls.join}\n#{line}"
        calls = []
      else bt << a[i]
      end
      i += 1
      m = m2
    end
  #  $log << RMTools::Painter.r("FORMAT DONE! #{bt.size} lines formatted")
    bt
  end
  
  module_function :format_trace
end

class Class
  
private
  def trace_format method
    if Exception.in ancestors
      self.__trace_format = method
    else
      raise NoMethodError, "undefined method `trace_format' for class #{self}"
    end
  end
  
end

    # 1.9 may hung up processing IO while generating traceback
if RUBY_VERSION < '1.9'
  class Exception
    alias :set_bt :set_backtrace
    class_attribute :__trace_format
    
    # to use trace formatting ensure that you have SCRIPT_LINES__ constant set
    # SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__
    #
    # If you also set (e.g. in irbrc file) 
    # module Readline
    #   alias :orig_readline :readline
    #   def readline(*args)
    #     ln = orig_readline(*args)
    #     SCRIPT_LINES__['(irb)'] << "#{ln}\n"
    #     ln
    #   end
    # end
    # it will be possible to get the lines entered in IRB
    # else it reads only ordinal require'd files
    def set_backtrace src
      if format = self.class.__trace_format
        src = RMTools.__send__ format, src
      end
      set_bt src
    end
  end
  
  class StandardError
    trace_format :format_trace
  end
  
  class SystemStackError
    trace_format false
  end
end
