# encoding: utf-8
module RMTools

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