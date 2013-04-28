# encoding: utf-8
RMTools::require 'console/coloring'
module RMTools

  def timer(ts=1, output=true)
    timez = ts - 1
    quiet, mute_warn = $quiet, $log.mute_warn
    $quiet = $log.mute_warn = true
    t1 = Time.now
    begin
      timez.times {yield} if timez > 0
    rescue
      $quiet, $log.mute_warn = quiet, mute_warn
      raise $!
    end
    res = yield
    t2 = Time.now
    ts.times {}
    t3 = Time.now.to_f*1000
    t2 = t2.to_f*1000
    t1 = t1.to_f*1000
    delta = (t2 - t1 - (t3 - t2)).round.to_f
    $quiet, $log.mute_warn = quiet, mute_warn
    res = res.inspect
    puts "#{output ? "res: #{res.size > 1000 ? res[0...999]+"…" : res}\n" : "size of res string: #{res.to_s.size}, "}one: #{Painter.gray '%0.4fms'%[delta/ts]}, total: #{Painter.gray "#{delta}ms"}"
  end
  
  module_function :timer
end