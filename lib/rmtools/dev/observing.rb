# encoding: utf-8
# Don't use it, it's slow as fuck
RMTools::require 'dev/binding'
require 'active_support/core_ext/class'

module RMTools

  # Makes binding stack as well as caller stack, 
  # which can be used to catch errors and directly operate within context 
  # in which error has been occured.
  class Observer
    cattr_reader :ignore_path, :ignore_gems, :ignore_names, :ignore_all_gems
    cattr_accessor :keep_binding_stack
    
    @@ignore_names = %w{irbrc.rb}
    @@ignore_all_gems = true
    
    @@binding_stack = []
    DefaultRescue = lambda {|e| 
        stop
        @@binding_stack.inspect_envs.present
        require 'irb'
        IRB.start('/usr/bin/irb18')
        @@binding_stack.last.start_interaction
        raise e
    }
    
    def self.ignore_names=ary
      @@ignore_names =ary
      update_ignore
    end
    def self.ignore_gems=ary
      @@ignore_gems =ary
      update_ignore
    end
    def self.ignore_all_gems=boolean
      @@ignore_all_gems = boolean
      update_ignore
    end
    
    def self.update_ignore
      @@ignore_path = %r{^(/usr/lib/ruby/(1.8/|gems/1.8/(bundler/)?gems/#{
        "(#{@@ignore_gems*'|'})" if !@@ignore_all_gems and @@ignore_gems
      })#{
        "|(#{@@ignore_names*'|'})" if @@ignore_names.b
      })}
    end
    
    def self.start
      @@binding_stack.clear
      @@keep_binding_stack = false
      set_trace_func proc {|event, file, line, id, binding_here, classname|
        if file !~ @@ignore_path
          if event == 'call'
            @@binding_stack << binding_here
          elsif !@@keep_binding_stack and event == 'return'
            @@binding_stack.pop
          elsif event == 'raise'
            @@binding_stack << binding_here
            @@keep_binding_stack = true
          end
          $log.debug {"#{event} by #{caller[2]} -> #{classname}##{id} <#{file}>; stack size = #{@@binding_stack.size}" if event.in %w{raise call return}}
        end
      }
    end
    
    def self.catch(rescue_proc=DefaultRescue)
      update_ignore
      start
      begin yield
      rescue => e
        @@keep_binding_stack = false
        begin
          rescue_proc[e]
        ensure
          @@binding_stack.clear
        end
      end
      stop
    end
    
    def self.stop
      set_trace_func nil
    end
    
    def self.trace_calls(out='log/calltrace.log')
      logger = RMLogger.new :out => out, :format => '[%time]: %text'
      offset, last_logline, quo, quos = 0, nil, 1, ''
      set_trace_func lambda {|event, file, line, id, binding, classname| 
        if event == 'call' or event == 'c-call' or event == 'raise'
          logline = "#{quos}\n#{'  '*([offset, 0].max)}#{classname}##{id} < #{file} > #{event=='c-call' ? '[CC]' : event == 'raise' ? '[RAISE]' : ''}"
          if last_logline != logline
            logger.log(last_logline = logline, RMLogger::INLINE) 
            quo = 1
            quos = ''
          else
            quo += 1
            quos = " x#{q}"
          end 
        end
        if event == 'call' or event == 'c-call'
          offset += 1
        elsif event == 'return' or event == 'c-return'
          offset -= 1
        end
      }
      begin yield
      rescue Exception
        nil
      ensure set_trace_func nil
      end
    end
    
  end
end