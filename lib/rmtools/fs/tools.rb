# encoding: utf-8
RMTools::require 'fs/io'

module RMTools
    
    def tail(file, bytes=1000)
      if File.file?(file)
        IO.read(file, bytes, File.size(file)-bytes)
      else
        STDERR.puts "#{file} is missed!"
      end
    end
    
    def tail_n(file, qty=10)
      if !File.file?(file)
        return STDERR.puts "#{file} is missed!"
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
  
    def read_lines(df, *lines)
      return if !lines or lines.empty?
      str = ""
      last = lines.max
      if File.file?(df)
        File.open(df, 'r') {|f|
          f.each {|line|
              no = f.lineno
              str << line if no.in lines
              break if no == last
        }}
        str
      else
        STDERR.puts "#{df} is missed!"
      end
    end
    
  module_function :tail, :tail_n, :read_lines
end