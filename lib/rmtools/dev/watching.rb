# encoding: utf-8
module RMTools
  
  class FileWatcher
    class_attribute :threads
    @@threads = {}
    
    def initialize(params={})
      @debug = params[:debug]
    end
    
    def files_stats(*stat_params)
      Dir(@pwd || Dir.pwd).recursive_content.flatten.map_hash {|fn| 
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
    
  end
  
  class ScpHelper < FileWatcher
    
    def initialize(params={})
      super
      @pwd = params[:pwd] || (params[:host] ? File.join(Dir.pwd, params[:host]) : Dir.pwd)
      @host = params[:host] || File.basename(@pwd)
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
        print "[ #{Painter.rb('Error')} ]: #{res}"
      else
        print "[ #{Painter.g('OK')} ]"
      end
    end
    
    def watch(opts={})
      thread_name = opts[:thread_name] || "scp_helper:#@host"
      # "период" здесь некорректно называть, 
      # так как он будет *больше* за счёт ожидания `scp`
      sleep_time = opts[:sleep_time] || 1
      if existed = @@threads[thread_name]
        existed.kill
      end
      @@threads[thread_name] = thread {
        cur_time, prev_time = Time.now, nil
        loop {
          cur_time, prev_time = Time.now, cur_time
          fpaths = files_mtimes.select {|f, s| s.mtime >= prev_time}.to_a.firsts
                      .map {|fpath| fpath.sub(@pwd, '')}
          if fpaths.b
            #$log << [prev_time.to_f, File.mtime(@pwd+fpaths[0]).to_f]
            puts Painter.w("\nMODIFIED IN #{@host}: ") + fpaths*', '
            fpaths.each {|fpath| scp fpath}
          else
            #$log << [prev_time.to_f, File.mtime('var/rails/nzm/app/assets/stylesheets/app.css').to_f]
            cur_time = prev_time 
          end
          sleep sleep_time
        }
      }
    end
    
  end
  
end