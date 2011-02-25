# encoding: utf-8
module Enumerable

  def rand
    if block_given?
      h, ua = {}, to_a.uniq
      size = ua.size
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
  end
  
  def randsample(qty=Kernel.rand(size))
    a, b = [], to_a.dup
    qty.times {a << b.rand!}
    a
  end

end