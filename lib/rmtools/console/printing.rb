# encoding: utf-8
module RMTools

  # transparent print: print text (or object details) and erase it
  class TempPrinter
    __init__
    
    def initialize object=nil, format=nil
      if @object = object
        @format = '"' + format.gsub(/:([a-z_]\w*)/, '#{@\1.inspect}') + '"'
      else
        @format = format
      end
    end
    
    def format_str params_hash=nil
      if params_hash
        params_hash.each {|k, v| @format.sub! ":#{k}", v.inspect}
      else
        @object.instance_eval @format
      end
    end

    def p(str=format_str)
      STDOUT << @eraser if @eraser
      cols = ENV['COLUMNS'].to_i
      astr = RUBY_VERSION < '1.9' ? UTF2ANSI[str] : str
      rows = astr.split("\n").sum {|line| 1 + line.size/cols}
      eraser = "\b" + "\r\b"*rows + " "
      @eraser = eraser + " "*cols*rows + eraser
      puts str
    end
    
    def end
      @eraser = nil
    end
    
    def clear
      p ""
    end
    
    def end!
      clear
      self.end
    end
    
  end
  
end

module RMTools

  def tick!
    print %W{|\b /\b -\b \\\b +\b X\b}.rand
  end
    
end