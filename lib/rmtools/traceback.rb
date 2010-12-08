module RMTools

  def format_trace a
    bt, calls, i = [], [], 0
  #  $log.info 'a.size', binding
    m = a[0].match(/^(.+):(\d+)(?::in `([^']+)')?$/)
    while i < a.size
  #    $log.info i
      m2 = a[i+1] && a[i+1].match(/^(.+):(\d+)(?::in `([^']+)')?$/)
  #    $log.info 'm', binding
  #    $log.info 'm2', binding
  #    $log.info 'm[3] m[1..2]==m2[1..2]', binding if m and m2
  #    $log.info 'm[1] m[2]', binding if m
  #    $log.info highlighted_line(*m[1..2]) if m
      if m and m[3] and m2 and m[1..2] == m2[1..2]
        calls.unshift " <- `#{m[3]}'"
      elsif m and m[1] !~ /\.gemspec$/ and line = highlighted_line(*m[1..2])
        bt << "#{a[i]}#{calls.join}\n#{line}"
        calls = []
      else bt << a[i]
      end
      i += 1
      m = m2
    end
  #  $log << Painter.r("FORMAT DONE! #{bt.size} lines formatted")
    bt
  end
  
  def highlighted_line_html file, line
    if File.file?(file)
      "   >>   <a style=\"color:#0A0; text-decoration: none;\"#{
        " href=\"http://#{
          defined?(DEBUG_SERVER) ? DEBUG_SERVER : 'localhost:8888'
        }/code/#{CGI.escape CGI.escape(file).gsub('.', '%2E')}/#{line}\""
      }>#{read_lines(file, line.to_i).chop}</a>" 
    end
  end

  def format_trace_html a
    bt, calls, i = [], [], 0
    m = a[0].match(/^(.+):(\d+)(?::in `([^']+)')?$/)
    while i < a.size
      m2 = a[i+1] && a[i+1].match(/^(.+):(\d+)(?::in `([^']+)')?$/)
      if m and m[3] and m2 and m[1..2] == m2[1..2]
        calls.unshift " <- `#{m[3]}'"
      elsif m and m[1] !~ /\.gemspec$/ and line = highlighted_line_html(*m[1..2])
        bt << "#{a[i]}#{calls.join}\n#{line}"
        calls = []
      else bt << a[i]
      end
      i += 1
      m = m2
    end
    bt
  end
  
  module_function :format_trace, :format_trace_html, :highlighted_line_html
end

    # 1.9 may hung up processing IO while generating traceback
if RUBY_VERSION < '1.9'

  class Class
    
    def trace_format method
      if new.kinda Exception
        if method; class_eval(%{
          def set_backtrace src
            src = #{method} src
            set_bt src
          end
        })
        else        class_eval(%{
          def set_backtrace src
            set_bt src
          end
        })
        end
      end
    end
  
  end

  class Exception
    alias :set_bt :set_backtrace
    
    # If you set (e.g. in irbrc file) IRB logging and Readline::TEMPLOG:
    # module Readline
    #   TEMPLOG = "path/to/logs/#{Time.now.to_i}.rb"
    #   alias :orig_readline :readline
    #   def readline(*args)
    #     ln = orig_readline(*args)
    #     RMTools::write TEMPLOG, "#{ln}\n"
    #     return ln
    #   end
    # end
    # it will be possible to get the lines entered in IRB
    # else it reads only ordinal require'd files
    
    trace_format :format_trace
    
  end
  
  SystemStackError.trace_format false
  
end
