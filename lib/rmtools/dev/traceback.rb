# encoding: utf-8
RMTools::require 'dev/trace_format'
require 'active_support/core_ext/class/attribute'

# As for rmtools-1.1.0, 1.9.1 may hung up processing IO while generating traceback
# As for 1.2.10 with 1.9.3 with readline support it isn't hung up anymore
# Still it's not suitable for Rails, too many raises inside the engine slow all the wor in 5-10 times.
# I need a way to format backtrace only in case it is actually about to be printed onto log or console/
unless ENV['RAILS_ENV']
  class Exception
    alias :set_bt :set_backtrace
    class_attribute :__trace_format
    
    # If you also set (e.g. in irbrc file) 
    #   module Readline
    #     alias :orig_readline :readline
    #     def readline(*args)
    #       ln = orig_readline(*args)
    #       SCRIPT_LINES__['(irb)'] << "#{ln}\n"
    #       ln
    #     end
    #   end
    # it will be possible to get the lines entered in IRB
    # else it reads only ordinal require'd files
    def set_backtrace src
      #message.hl! self.class
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
