# encoding: utf-8
RMTools::require 'core'
RMTools::require 'console/coloring'
RMTools::require 'text/string_parse'

module RMTools
  ## Lazy logger
  ## with timer, coloring and caller hints
  # Usage:
  #> $log <= "Starting process..."
  # 13:43:01.632 DEBUG [(irb):1 :irb_binding]: Starting process...
  #> $log << ["Got response:", {code: 200, body: "Hello"}]
  # 13:43:20.524 INFO [(irb):2 :irb_binding]: ["Got response:", {:code=>200, :body=>"Hello"}]
  # $log < "Oops, something went wrong!"
  # 13:43:32.030 WARN [(irb):3 :irb_binding]: Oops, something went wrong!
  #
  # which is aliases of #debug, #info and #warn, consequently
  ##
  # If you want to wrap logger call into another method:
  #> class Exception
  #>   def warn!
  #>     $log.warn "#{self.class} – #{message}", caller: 2
  #>   end
  #> end
  # but still see in log string a reference to that method calling Exeption#warn!
  # just pass stack frames quantity as :caller param
  ##
  # If you want to log an info that need a calculations
  # (remember, #inspect is a calculations as well)
  # to be logged, but don't want a production server
  # to calculate this,
  # you may pass that calculations in a block:
  #> $log.debug {a_large_object}
  # and it won't run if #debug should not run at this moment
  ##
  # Log level might be set for one server or console session using ENV variables:
  # LOGLEVEL={DEBUG | INFO | WARN | ERROR}
  # or
  # DEBUG=1 | WARN=1 | SILENT=1
  # Default log level is INFO
  ##
  class RMLogger
    __init__
    attr_accessor :mute_info, :mute_error, :mute_warn, :mute_log, :mute_debug
    attr_reader :default_format, :log_level
        
    Modes = [:debug, :log, :info, :warn, :error]
    NOPRINT = 8
    NOLOG = 4
    PREV_CALLER = 2
    INLINE = 1
  
    def initialize format={}
      @c = Painter
      @highlight = {
          :error => @c.red_bold("ERROR"),
          :warn => @c.red_bold("WARN"),
          :log => @c.cyan("INFO"),
          :info => @c.cyan_bold("INFO"),
          :debug => @c.gray_bold("DEBUG")
      }
      @file_formats = Hash.new(@default_format = {})
      set_format :global, format
      
      if ENV['LOGLEVEL']
        self.log_level = ENV['LOGLEVEL']
      elsif ENV['DEBUG'] || ENV['VERBOSE']
        self.log_level = 'DEBUG'
      elsif ENV['WARN'] || ENV['QUIET']
        self.log_level = 'WARN'
      elsif ENV['SILENT']
        self.log_level = 'ERROR'
      else
        self.log_level = 'INFO'
      end
    end
          
    def _set_format file, format
      file.print = !format.q
      file.out = format.out || format.log_file
      file.color_out = format.color_out || format.color_log
      file.detect_comments = !!format.detect_comments
      file.precede_comments = format.precede_comments || "# "
                
      file.path_format = '%'.in file.out if file.out
      file.tf   = format.time.to_a
      file.cf0 = format.caller
      file.cf = file.cf0.sub('%p') {'\1'}.sub('%f') {'\2'}.sub('%l') {'\3'}.sub('%m') {'\4'}
      file.fmt = format.format
      file._time, file._caller = '%time'.in(file.fmt), '%caller'.in(file.fmt)
    end
          
    def defaults
      Kernel::puts %{    # #{@c.y 'common options:'}
    :q => false,   # not print
    :out => false, # output to file, may contain strftime's %H%M%Y etc for filename
    :time => ["%H:%M:%S", "%03d"], # strftime, [msecs]
    :type => :console, # or :html
    # #{@c.y 'console values:'}
    :caller => "#{@c.gray('%f:%l')} #{@c.red_bold(':%m')}", # "file:line :method", %p is for fullpath
    :format => "%time %mode [%caller]: %text" # format of entire log string, %mode is {#{%w(debug log info warn).map {|i| @highlight[i.to_sym]}*', '}}
    :color_out => false, # do not clean control characters that make output to file colorful; set to true makes more readable output of `tail' but hardly readable by gui file output
    :detect_comments => false, # highlight and strip comments blocks
    :precede_comments => "# ",
    # :detect_comments with default :precede_comments allows comment blocks looking like:
    $log<<<<-'#'
    # ... comment string one ...
    # ... comment string two ...
    #
    be logged like #{@c.green "\n# ... comment string one ...\n# ... comment string two ..."}
    # #{@c.y 'html options:'}
    :caller => "<a class='l'>%f:%l</a> <a class='m'>:%m</a>",
    :format => "<div class='line'><a class='t'>%time</a> <a class='%mode'>%mode</m> [%caller]: <p>%text</p>%att</div>", # %att is for array of objects that should be formatted by the next option
    :att =>"<div class='att'><div class='hide'>+</div><pre>%s</pre></div>", # .hide should be scripted to work like a spoiler
    :serializer => RMTools::RMLogger::HTML # should respond to :render(obj); nil value means each object will be just #inspect'ed}
    end
    alias :usage :defaults
          
    # set any needed params, the rest will be set by default
    def set_format *args
      global, format = args.fetch_opts [nil], :type => :console, :time => ["%H:%M:%S", "%03d"]                  
      format = if format[:type] == :html; {
                    :caller => "<a class='l'>%f:%l</a> <a class='m'>:%m</a>", 
                    :format => "<div class='line'><a class='t'>%time</a> <a class='%mode'>%mode</m> [%caller]: <p>%text</p>%att</div>",
                    :att =>"<div class='att'><div class='hide'>+</div><pre>%s</pre></div>",
                    :serializer => RMTools::RMLogger::HTML
                  }; else {
                    :caller => "#{@c.gray('%f:%l')} #{@c.red_bold(':%m')}", 
                    :format => "%time %mode [%caller]: %text"
                  } end.merge format
      if global
        _set_format @default_format, format
      else
        _set_format(file_format={}, format)
        @file_formats[File.expand_path(caller[0].till ':')] = file_format
      end
    end
          
    def get_format file=nil
      cfg = @file_formats[file && File.expand_path(file)]
      modes = Modes.reject {|m| send :"mute_#{m}"}
      %{<Logger #{cfg.fmt.sub('%time', "%time(#{cfg.tf*'.'})").sub('%caller', "%caller(#{cfg.cf0})")}#{' -> '+cfg.out if cfg.out} #{modes.b ? modes.inspect : 'muted'}>}
    end
            
    # TODO: добавить фильтров, 
    # например, для обработки текста, который будет логирован
    def _print mode, text, opts, caler, bind, cfg
      log_ = opts&NOLOG==0
      print_ = opts&NOPRINT==0
      str = cfg.fmt.dup
      str.gsub! "%mode", @highlight[mode]
      if bind
        text = bind.report text
      elsif !text.is String
        text = text.inspect
      elsif cfg.detect_comments and text =~ /\A[ \t]*#[ \t]+\S/
        text = "\n" + @c.green(text.gsub(/^([ \t]*#[ \t])?/, cfg.precede_comments).chop)
      end
      out = cfg.out
      if cfg._time or cfg.path_format
        now = Time.now
        if cfg._time
          time = now.strftime cfg.tf[0]
          time << ".#{cfg.tf[1]%[now.usec/1000]}" if cfg.tf[1]
          str.gsub! "%time", time
        end
        out = now.strftime cfg.out if cfg.path_format
      end
      if caler
        caler.sub!(/block (?:\((\d+) levels\) )?in/) {"{#{$1||1}}"}
        str.gsub! "%caller", caler.sub(String::SIMPLE_CALLER_RE, cfg.cf)
      end
      str.gsub! "%text", text
      str << "\n" if opts&INLINE==0
      log_str = cfg.color_out ? str : @c.clean(str)
      RMTools.write out, log_str if log_
      Kernel::print str if print_
    end
        
    def get_config!
      @file_formats.empty? ? @default_format : @file_formats[File.expand_path((@current_caller = caller)[1].till ':')]
    end
        
    def get_config(file=nil)
      @file_formats[file && File.expand_path(file)]
    end
        
    # controls:
    # - @mute_warn, @mute_info, @mute_log, @mute_debug: 
    #       do not print this messages regardless of any globals
    # - @out_all: write to file info and debug messages
    # - @out:      write to file
    # - @print:    write to stdout
        
    def error *args
      cfg = get_config!
      if (cfg.out or cfg.print) && !@mute_error
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !cfg.out
        opts[:mute] |= NOPRINT if !cfg.print
        return if block_given? && (text = yield).nil?
        _print(:error, text, opts[:mute], cfg._caller && (@current_caller || caller)[(opts[:caller] || opts[:caller_offset]).to_i], bind, cfg)
      end  
    end
        
    def warn *args
      cfg = get_config!
      if (cfg.out or cfg.print) && !@mute_warn
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !cfg.out
        opts[:mute] |= NOPRINT if !cfg.print
        return if block_given? && (text = yield).nil?
        _print(:warn, text, opts[:mute], cfg._caller && (@current_caller || caller)[(opts[:caller] || opts[:caller_offset]).to_i], bind, cfg)
      end  
    end
        
    def log *args
      cfg = get_config!
      if (cfg.out or cfg.print) && !@mute_log
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !cfg.out
        opts[:mute] |= NOPRINT if !(cfg.print && !@mute_debug)
        return if block_given? && (text = yield).nil?
        _print(:log, text, opts[:mute], cfg._caller && (@current_caller || caller)[(opts[:caller] || opts[:caller_offset]).to_i], bind, cfg)
      end
    end
            
    def info *args
      cfg = get_config!
      if (cfg.print or cfg.out && cfg.out_all) && !@mute_info
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !(cfg.out && cfg.out_all)
        opts[:mute] |= NOPRINT if !cfg.print
        return if block_given? && (text = yield).nil?
        _print(:info, text, opts[:mute], cfg._caller && (@current_caller || caller)[(opts[:caller] || opts[:caller_offset]).to_i], bind, cfg)
      end 
    end
          
    def debug *args
      cfg = get_config!
      if (cfg.print or cfg.out && cfg.out_all) && !@mute_debug
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !(cfg.out && cfg.out_all)
        opts[:mute] |= NOPRINT if !cfg.print
        return if block_given? && (text = yield).nil?
        _print(:debug, text, opts[:mute], cfg._caller && (@current_caller || caller)[(opts[:caller] || opts[:caller_offset]).to_i], bind, cfg)
      end 
    end
          
    alias :<= :debug
    alias :<< :info
    alias :puts :info
    alias :<   :warn
    alias :fatal :error
    
    def print text
      info text, caller: 1, mute: INLINE 
    end
    
    def log_level=(level)
      unless level.is_a? Integer
        level = ::Logger.const_get(level.to_s.upcase)
      end
      @log_level = level
      self.debug = level < 1
      self.info     = level < 2
      self.log      = level < 2
      self.warn   = level < 3
      self.error   = level < 4
    end
        
    Modes.each {|m| define_method("#{m}=") {|mute| send :"mute_#{m}=", !mute}}
    
    %w(out_all print out).each {|m| 
      define_method m do @default_format.__send__ m.to_sym 
      end
      define_method m+'=' do |x| @default_format.__send__ :"#{m}=", x
      end
    }
        
    def inspect() get_format end
          
  end
      
  # Default global logger now initialized here
  # I believe it wouldn't hurt you
  $log = RMLogger.new
end