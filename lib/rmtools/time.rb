# encoding: utf-8
module RMTools

  def timer(ts=1, output=true)
    timez = ts - 1
    panic, verbose = $panic, $verbose
    $panic = $verbose = false
    t1 = Time.now
    timez.times {yield}
    res = yield
    t2 = (Time.now.to_f*1000).round
    t1 = (t1.to_f*1000).round
    $panic, $verbose = panic, verbose
    res = res.inspect
    puts "#{output ? "res: #{res.size > 1000 ? res[0...1000]+"…" : res}\n" : "size of res string: #{res.to_s.size}, "}one: #{(t2-t1).to_f/ts}ms, total: #{(t2-t1).to_f}ms"
  end
    
  def puttime(ms=nil)
    t = Time.now
    if ms
      t.strftime("%H:%M:%S")+sprintf(".%03d ", t.usec/1000)
    else
      t.strftime("%d.%m.%y %H:%M:%S ")
    end
  end
    
  def putdate
    Time.now.strftime("%d.%m.%y")
  end
  
  module_function :puttime, :putdate
end
