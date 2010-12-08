# encoding: utf-8
class Dir
  
  def include?(name)
    #content.map {|f| File.split(f)[1]}.include? name
    entries.include? name
  end
  
  def recursive_content(flat=true)
    list = []
    cont = content.map {|f|
      if File.directory?(f)
             rc = Dir.new(f).recursive_content.map {|f| f.sub(/^\.\//, '')} 
             flat ? list.concat(rc) : rc
      else flat ? (list << f) : f 
      end
    }
    (flat ? list : cont)
  end
  
  def content
    Dir["#{path}/**"].b || to_a[2..-1].sort.map {|c| File.join path, c}
  end
  
  def parent
    newpath = File.dirname(path)
    Dir.new(newpath) if newpath != path 
  end
  
  def child(idx)
    df = content[idx]
    if File.file?(df)
      File.new(df)
    elsif File.directory?(df)
      Dir.new(df)
    end
  end
  
  def children
    content.map {|df| 
      if File.file?(df)
        File.new(df)
      elsif File.directory?(df)
        Dir.new(df)
      end                    
    }
  end
  
  def refresh
    return if !File.directory?(path)
    Dir.new(path)
  end
  
  def inspect
    displaypath = case path
          when /^(\/|\w:)/ then path
          when /^\./ then File.join(Dir.pwd, path[1..-1])
          else File.join(Dir.pwd, path)
        end
    "<#Dir \"#{displaypath}\" #{to_a.size - 2} elements>"
  end
  
  def name
    File.basename(path)
  end
  
  # Fixing windoze path problems
  # requires amatch gem for better performance
  def real_name
    n, p, count = name, parent, []
    return n if !p
    pp, pc, sc = parent.path, parent.to_a[2..-1], to_a
    if defined? Amatch
      ms = pc.sizes.max
      count = [:hamming_similar, :levenshtein_similar, :jaro_similar].sum {|m| pc.group_by {|_| _.upcase.ljust(ms).send(m, n)}.max[1]}.count.to_a
      max = count.lasts.max
      res = count.find {|c|
        c[1] == max and File.directory?(df=File.join(pp, c[0])) and Dir.new(df).to_a == sc
      }
      return res[0] if res
    end
    (pc - count).find {|c|
      File.directory?(df=File.join(pp, c)) and Dir.new(df).to_a == sc
    }
  end
  
end

class File
  
  def inspect
    "<#File \"#{path}\" #{closed? ? 'closed' : stat.size.bytes}>"
  end
  
  def self.include?(name, str)
    f = new name, 'r'
    incl = f.include? str
    f.close
    incl
  end
  
  def include?(str)
    while s = gets do return true if s.include? str end
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
  
  def self.modify(file, bak=true)
    orig_text = read file
    text = yield orig_text
    rename file, file+'.bak' if bak
    RMTools.rw(file, text.is(String) ? text : orig_text)
  end
  
  def cp(df)
    dir = File.dirname df
    FileUtils.mkpath dir unless File.directory? dir
    FileUtils.cp path, df
  end

  def mv(df)
    dir = File.dirname df
    FileUtils.mkpath dir unless File.directory? dir
    rename df
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
      count = [:hamming_similar, :levenshtein_similar, :jaro_similar].sum {|m| pc.group_by {|f| (ext ? f[0..-(ext.size+2)] : f).upcase.ljust(ms).send(m, n)}.max[1]}.count.to_a
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
  
  PathMemo = {} if !defined? PathMemo
  def self.real_path path, memo=1
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
  
  def self.real_name(df)
    if file?(df)
        new(df).real_name
    elsif directory?(df)
        Dir.new(df).real_name
    end
  end
  
end

class IO
  
  def gets2
    str = ''
    str << (c = read 1) until c and "\r\n\b".include? c or eof?
    str 
  end
  
end

module RMTools

    def tick!
      print %W{|\b /\b -\b \\\b +\b X\b}.rand
    end
    
    def executing? file
      caller(0)[0] =~ /^#{file}:/
    end

    def rw(df, value=nil)
      return false if value.nil?
      df.gsub!('\\', '/')
      path = File.dirname(df)
      FileUtils.mkpath(path) if !File.directory?(path)
      mode = RUBY_VERSION > '1.9' ? :wb : 'wb'
      File.open(df, mode) {|f| f << value}
      value.size
    end
  
    def write(df, value='', pos=0)
      return false if value.nil?
      df.gsub!('\\', '/')
      path = File.dirname(df)
      FileUtils.mkpath(path) if !File.directory?(path)
      if pos == 0
        mode = RUBY_VERSION > '1.9' ? :ab : 'ab'
        File.open(df, mode) {|f| f << value}
      else
        if pos < 0
          raise IndexError, "file #{df} does not exist, can't write from position #{pos}" if !File.file?(df)  
          raise IndexError, "file #{df} is shorter than #{(-pos).bytes}, can't write from position #{pos}" if (size = File.size(df)) < -pos  
          pos = size + pos
        end
        File.open(df, 'r+') {|f| f.pos = pos; f << value}
      end
      value.size
    end
  
    def read(df, mode='rb')
      df.gsub!('\\', '/')
      if !File.file?(df)
        $log.debug "#{df} is missed!"
      else
        File.open(df, mode) {|f| f.read}
      end
    end
  
    def read_lines(df, *lines)
      return if !lines or lines.empty?
      str = ""
      last = lines.max
      if !File.file?(df)
        puts "#{df} is missed!"
      else
        File.open(df, 'r') {|f|
          f.each {|line|
              no = f.lineno
              str << line if no.in lines
              break if no == last
        }}
        str
      end
    end
    
    def highlighted_line(file, line)
      if defined? SCRIPT_LINES__
        "   >>   #{Painter.green SCRIPT_LINES__[file][line.to_i - 1].chop}" if SCRIPT_LINES__[file]
      else
        file = Readline::TEMPLOG if file == '(irb)' and defined? Readline::TEMPLOG
        "   >>   #{Painter.green read_lines(file, line.to_i).chop}" if File.file? file
      end
    end
    
    def tail(file, bytes=1000)
      if !File.file?(file)
        puts "#{file} is missed!"
      else
        IO.read(file, bytes, File.size(file)-bytes)
      end
    end
    
    def tail_n(file, qty=10)
      if !File.file?(file)
        return puts "#{file} is missed!"
      end
      size = File.size(file)
      lines = []
      strlen = 0
      step = qty*100
      while qty > 0 and (offset = size-strlen-step) >= 0 and (str = IO.read(file, step, offset)).b
        i = str.index("\n") || str.size
        strlen += step - i
        new_lines = str[i+1..-1]/"\n"
        qty -= new_lines.size
        lines = new_lines.concat(lines)
      end
      lines[-qty..-1]
    end
  
  module_function :tick!, :executing?, :rw, :write, :read, :read_lines, :highlighted_line, :tail, :tail_n
end