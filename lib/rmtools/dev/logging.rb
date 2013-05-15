# encoding: utf-8
RMTools::require 'console/coloring'
RMTools::require 'text/string_parse'
RMTools::require 'b'

module RMTools

  # lazy logger
  # with caller processing and highlighting
  class RMLogger
    __init__
    attr_accessor :mute_info, :mute_warn, :mute_log, :mute_debug
    attr_reader :default_format
        
    Modes = [:debug, :log, :info, :warn]
    NOPRINT = 8
    NOLOG = 4
    PREV_CALLER = 2
    INLINE = 1
  
    def initialize format={}
      @c = Painter
      @highlight = {
          :warn => @c.red_bold("WARN"),
          :log => @c.cyan("INFO"),
          :info => @c.cyan_bold("INFO"),
          :debug => @c.gray_bold("DEBUG")
      }
      @file_formats = Hash.new(@default_format = {})
      set_format :global, format
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
      puts %{    # #{@c.y 'common options:'}
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
      Kernel.print str if print_
    end
        
    def get_config!
      @file_formats.empty? ? @default_format : @file_formats[File.expand_path((@current_caller = caller)[1].till ':')]
    end
        
    # controllers:
    # - $panic: print debug messages
    # - $verbose: print log messages
    # - $quiet: print only warn messages regardless of other globals
    # - @mute_warn, @mute_info, @mute_log: do not print
    #                       this messages regardless of any globals
    # - @out_all: write to file any messages
        
    def warn *args
      cfg = get_config!
      if (cfg.out or cfg.print) && !@mute_warn
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !cfg.out
        opts[:mute] |= NOPRINT if !cfg.print
        return if block_given? && (text = yield).nil?
        _print(:warn, text, opts[:mute], cfg._caller && (@current_caller || caller)[opts[:caller].to_i], bind, cfg)
      end  
    end
        
    def log *args
      cfg = get_config!
      if (cfg.out or cfg.print && !$quiet && $verbose) && !@mute_log
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !cfg.out
        opts[:mute] |= NOPRINT if !(cfg.print && !$quiet && $verbose)
        return if block_given? && (text = yield).nil?
        _print(:log, text, opts[:mute], cfg._caller && (@current_caller || caller)[opts[:caller].to_i], bind, cfg)
      end
    end
            
    def info *args
      cfg = get_config!
      if (cfg.print && !$quiet or cfg.out && cfg.out_all) && !@mute_info
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !(cfg.out && cfg.out_all)
        opts[:mute] |= NOPRINT if !(cfg.print && !$quiet)
        return if block_given? && (text = yield).nil?
        _print(:info, text, opts[:mute], cfg._caller && (@current_caller || caller)[opts[:caller].to_i], bind, cfg)
      end 
    end
          
    def debug *args
      cfg = get_config!
      if (cfg.print && $panic && !$quiet or cfg.out && cfg.out_all) && !@mute_debug
        text, bind, opts = args.get_opts [!block_given? && args[0].kinda(Hash) ? args[0] : "\b\b ", nil], :mute => 0
        opts[:mute] |= NOLOG if !(cfg.out && cfg.out_all)
        opts[:mute] |= NOPRINT if !(cfg.print && $panic && !$quiet)
        return if block_given? && (text = yield).nil?
        _print(:debug, text, opts[:mute], cfg._caller && (@current_caller || caller)[opts[:caller].to_i], bind, cfg)
      end 
    end
          
    alias :<= :debug
    alias :<< :info
    alias :<   :warn
        
    Modes.each {|m| define_method("#{m}=") {|mute| send :"mute_#{m}=", !mute}}
    
    %w(out_all print out).each {|m| 
      define_method m do @default_format.__send__ m.to_sym 
      end
      define_method m+'=' do |x| @default_format.__send__ :"#{m}=", x
      end
    }
        
    def inspect() get_format end
          
  end
      
  # default logger now initialized here
  $log = RMLogger.new
end