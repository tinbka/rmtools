module RMTools

  def threadify(ary, max_threads=4)
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

  module_function:threadify
end