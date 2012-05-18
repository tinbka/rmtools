# encoding: utf-8
RMTools::require 'fs/io'

class File
  PathMemo = {} if !defined? PathMemo
  
  def inspect
    "<#File \"#{path}\" #{closed? ? 'closed' : stat.size.bytes}>"
  end
  
  class << self
  
    def real_path path, memo=1
      a = expand_path(path).split(/[\/\\]/)
      a.each_index {|i|
        if a[j=-(i+1)]['~']
          n = i+2>a.size ? a[j] : join(a[0..-(i+2)], a[j])
          a[j] = PathMemo[n] || real_name(n) 
          PathMemo[n] = a[j] if memo
        else break
        end
      }
      a*'/'
    end
    
    def real_name(df)
      if file?(df)
        new(df).real_name
      elsif directory?(df)
        Dir.new(df).real_name
      end
    end
  
    def modify(pattern, bak=true, &block)
      Dir[pattern].select {|file| __modify(file, bak, &block)}
    end
    
  
    def include?(name, str)
      f = new name, 'r'
      incl = f.include? str
      f.close
      incl
    end
    
    private
      def __modify(file, bak=true)
        if orig_text = read(file)
          copy_text = orig_text.dup
          res_text = yield copy_text
          # res may be nil in case of gsub! 
          # though copy_text wouldn't be equal orig_text if something has been changed
          if orig_text != res_text and (res_text or orig_text != copy_text)
            rename file, file+'.bak' if bak
            RMTools.rw(file, res_text.is(String) ? res_text : copy_text)
          end
        end
      end
  end
  
  def include?(str)
    while s = gets
      return true if s.include? str 
    end
  end
  
  def parent
    newpath = File.dirname(path)
    Dir.new(newpath) if newpath != path
  end
  
  def name
    File.basename(path)
  end

  def ext
    name[/[^.]+$/]
  end
  
  def refresh
    return if !File.file?(path)
    close
    File.new(path,'r')
  end  
  
  def cp(df)
    dir = File.dirname df
    FileUtils.mkpath dir unless File.directory? dir
    FileUtils.cp path, df
  end

  def mv(df)
    dir = File.dirname df
    FileUtils.mkpath dir unless File.directory? dir
    File.rename path, df
  end
  
  # Fixing windoze path problems
  # requires amatch gem for better performance
  def real_name
    n, p, count = name, parent, []
    pp, pc, ss = parent.path, parent.to_a[2..-1], stat
    ms = pc.sizes.max
    n, ext = n.rsplit('.', 2)
    if ext
      re = /\.#{ext}$/i
      pc.reject! {|f| !f[re]}
    end
    if defined? Amatch
      count = [:hamming_similar, :levenshtein_similar, :jaro_similar].sum {|m| pc.group_by {|f| (ext ? f[0..-(ext.size+2)] : f).upcase.ljust(ms).send(m, n)}.max[1]}.arrange.to_a
      max = count.lasts.max
      res = count.find {|c|
        c[1] == max and File.file?(df=File.join(pp, c[0])) and File.stat(df) == ss
      }
      return res[0] if res
    end
    (pc - count).find {|c|
      File.file?(df=File.join(pp, c)) and File.stat(df) == ss
    }
  end
  
end
