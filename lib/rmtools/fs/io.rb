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
  
  def self.prepare_write(df, value)
    return false if value.nil?
    value = value.inspect unless value.class == String
    value = value.force_encoding('UTF-8') if RUBY_VERSION > '1.9'
    df = df.tr '\\', '/'
    path = File.dirname(df)
    FileUtils.mkpath(path) if !File.directory?(path)
    yield df, value
    value.size
  end
  
  def rw(df, value=nil)
    RMTools::prepare_write df, value do
      File.open(df, File::CREAT|File::WRONLY|File::TRUNC) {|f| f << value}
    end
  end

  def write(df, value='', pos=0)
    RMTools::prepare_write df, value do
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
    end
  end  
  
    #    read('filename')
    ### => 'text from filename'
    #    read('nonexistent_filename')
    # couldn't read from "nonexistent_filename" (called from (irb):9001)
    ### => nil
    #    read(['file1', 'file2', 'file3'])
    ### => 'text from first of file1, file2, file3 that exists'
    #    read(['file1', 'file2'], ['nonexistent_file1', 'nonexistent_file2'])
    # coludn't read from neither "nonexistent_file1", nor "nonexistent_file2" (called from (irb):9003)
    ### => ['text from first of file1, file2 that exists', nil]
    #    read('file1', 'file2')
    ### => ['text from file1', 'text from file2]
    #    read('file1', ['file2', 'file3'])
    ### => ['text from file1', 'text from first of file2 and file3 that exists']
    def read(*dests)
      texts = dests.map {|dest|
        dest = dest[0] if dest.size == 1
        if dest.is Array
          if file = dest.find {|f| File.file?(f.tr '\\', '/')}
            File.open(file.tr('\\', '/'), File::RDONLY) {|f| f.read}
          else
            warn "couldn't read from neither #{dest[0].inspect} nor #{dest[1..-1].inspects*' nor '}; files missed (called from #{caller[2]})"
          end
        else
          if File.file? dest.tr('\\', '/')
            File.open(dest.tr('\\', '/'), File::RDONLY) {|f| f.read}
          else
            warn "couldn't read from #{dest.inspect}; file missed (called from #{caller[2]})"
          end
        end
      }
      texts = texts[0] if texts.size == 1
      texts
    end
  
  module_function :read, :write, :rw
end