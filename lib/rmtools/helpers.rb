module RMTools
  module Helpers
  
    def executing? file=$0
      caller[0] =~ /^#{file}:/
    end
  
    def thread(&block)
      Thread.new(&block)
    end
    
  end
end