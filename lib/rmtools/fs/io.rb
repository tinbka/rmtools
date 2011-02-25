# encoding: utf-8
require 'fileutils'

class IO
  
  def gets2
    str = ''
    str << (c = read 1) until c and "\r\n\b".include? c or eof?
    str 
  end
  
end

module RMTools

    def rw(df, value=nil)
      return false if value.nil?
      df = df.tr '\\', '/'
      path = File.dirname(df)
      FileUtils.mkpath(path) if !File.directory?(path)
      File.open(df, File::CREAT|File::WRONLY|File::TRUNC) {|f| f << value}
      value.size
    end
  
    def write(df, value='', pos=0)
      return false if value.nil?
      df = df.tr '\\', '/'
      path = File.dirname(df)
      FileUtils.mkpath(path) if !File.directory?(path)
      if pos == 0
        File.open(df, File::CREAT|File::WRONLY|File::APPEND) {|f| f << value}
      else
        if pos < 0
          if !File.file?(df)  
            raise IndexError, "file #{df} does not exist, can't write from position #{pos}" 
          elsif (size = File.size(df)) < -pos 
            raise IndexError, "file #{df} is shorter than #{(-pos).bytes}, can't write from position #{pos}"
          end
          pos = size - pos
        end
        File.open(df, File::CREAT|File::WRONLY) {|f| f.pos = pos; f << value}
      end
      value.size
    end
  
    def read(df)
      df = df.tr '\\', '/'
      if File.file?(df)
        File.open(df, File::RDONLY) {|f| f.read}
      else
        STDERR.puts "couldn't read from #{df.inspect}; file missed"
      end
    end
  
  module_function :rw, :write, :read
end