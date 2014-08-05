module RMTools
  module Helpers
  
    def executing? file=$0
      caller[0] =~ /^#{file}:/
    end
  
    def thread(&block)
      Thread.new(&block)
    end
    
    def forkify(ary, max_threads=4)
      forks = []
      ary.each do |e|
        if max_threads > forks.size
          forks << fork { yield e }
        end
        if max_threads == forks.size
          forks.delete Process.wait
        end
      end
      Process.waitall
    end
    
  end
end