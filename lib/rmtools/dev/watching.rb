# encoding: utf-8
module RMTools
  
  class FileWatcher
    cattr_reader :threads
    attr_reader :thread
    @@threads = {}
    
    def initialize(params={})
      @debug ||= params[:debug]
      @pwd ||= params[:pwd] || Dir.pwd
      @thread_name ||= params[:thread_name] || "#{self.class.name.underscore}:#@host"
      @interval ||= params[:interval] || 1
    end
    
    def files_stats(*stat_params)
      opts = {recursive: true, include_dot: true}.merge(stat_params.extract_options!)
      Dir(@pwd || Dir.pwd).content(opts).map_hash {|fn| 
        if File.file? fn
          if stat_params
            stats = stat_params.map_hash {|param| 
              [param, File.__send__(param, fn)]
            }
          else
            stats = File.stats fn
          end
          [fn, stats]
        end
      } 
    end
    
    def kill
      @@threads[@thread_name].kill
    end
    
    def temp_string(str, color=nil)
      # space is needed because cursor is on the left
      str = "  " + str.to_s
      backspace = "\b"*str.size
      if color
        str = Painter.send(color, str)
      end
      str << backspace
    end
    
    def print_temp(str, color=nil)
      print temp_string str, color
    end
    
    def puts_temp(str, color=nil)
      print_temp(str.to_s+"\n", color)
    end
    
    def watch(opts={})
      if @@threads[@thread_name]
        kill
      end
      @@threads[@thread_name] = @thread = Thread.new {
        loop {watch_cycle}
      }
    end
    
    # Памятка про printf для чисел:
    # precision = минимальное число цифр; 
    #   %f -> справа || 6
    #   %d -> слева, заполняется нулями || 1
    # len = минимальная длина строки; если начинается с 0, заполняется нулями, иначе пробелами || 0
    # "%[<len>.][<precision>]d"
    # "%[<len>][.<precision>]f"
    def print_time(seconds)
      minutes, seconds = seconds.to_i.divmod 60
      hours, minutes = minutes.divmod 60
      diff = "#{"#{hours}:" if hours.b}#{"%2d:"%minutes if hours.b or minutes.b}#{"%2d"%seconds}"
      print_temp(diff, :b_b)
    end
    
    def print_idle_time
      print_time(Time.now - @cur_time)
    end
    
    def watch_cycle
      @files = select_files
      process
      wait
    end
    
    # => [pathname, ...] or {pathname => [action, ...]} or {pathname => action}
    def select_files
      {}
    end
    
    def process
      raise NotImplementedError, "do something with @files"
    end
    
    def wait
      sleep @interval
    end
    
  end
  
  class ScpHelper < FileWatcher
    
    def initialize(params={})
      @pwd = params[:pwd] || (params[:host] ? File.join(Dir.pwd, params[:host]) : Dir.pwd)
      @host = params[:host] || File.basename(@pwd)
      super params
    end
    
    def files_mtimes
      files_stats :mtime
    end
    
    # @ fpath : "/<relative path>"
    def scp(fpath)
      fullpath = File.join @pwd, fpath
      cmd = "scp #{fullpath.inspect} #{[@host, fpath].join(':').inspect} 2>&1"
      print "`#{cmd}`: " if @debug
      if res = RMTools::tick_while {`#{cmd}`}.b
        puts "[ #{Painter.r_b('Error')} ]: #{res}"
      else
        print "[ #{Painter.g('OK')} ]"
      end
    end
    
    def watch
      @cur_time, @prev_time = Time.now, nil
      super
    end
    
    def select_files
      @cur_time, @prev_time = Time.now, @cur_time
      files_mtimes.select {|f, s| s.mtime >= @prev_time}.to_a.firsts
      .map {|fpath| fpath.sub(@pwd, '')}
    end
    
    def process
      if @files.b
        $log.debug {[prev_time.to_f, File.mtime(@pwd+@files[0]).to_f]}
        puts Painter.w("\nMODIFIED IN #@host: ") + @files*', '
        @files.each {|fpath| scp fpath}
      else
        $log.debug {[@prev_time.to_f, File.mtime('var/rails/nzm/app/assets/stylesheets/app.css').to_f]}
        @cur_time = @prev_time 
      end
    end
    
    def wait
      (@interval*10).times {
        sleep 0.1
        print_idle_time
      }
    end
    
  end
  
end