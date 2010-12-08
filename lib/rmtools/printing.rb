module RMTools

  class TempPrinter
    __init__
    
    def initialize object=nil, format=nil
      if @object = object
        @format = '"' + format.gsub(/:([a-z_]\w*)/, '#{@\1.inspect}') + '"'
      end
    end
    
    def format_str
      @object.instance_eval @format
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