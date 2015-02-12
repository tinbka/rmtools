# encoding: utf-8
module Enumerable

  def rand(*args)
    if args.empty?
      if block_given?
        h, ua = {}, to_a.uniq
        s = ua.size
        loop {
          i = Kernel.rand size
          if h[i]
            return if h.size == s
          elsif yield(e = ua[i])
            return e
          else h[i] = true
          end
        }
      else to_a[Kernel.rand(size)]
      end
    else
      Kernel.rand(*args)
    end
  end
  
  def randsample(qty=Kernel.rand(size))
    a, b = [], to_a.dup
    [qty, size].min.times {a << b.rand!}
    a
  end

end