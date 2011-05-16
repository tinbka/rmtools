# encoding: utf-8
RMTools::require 'console/coloring'

module RMTools

  def timer(ts=1, output=true)
    timez = ts - 1
    quiet, mute_warn = $quiet, $log.mute_warn
    $quiet = $log.mute_warn = true
    t1 = Time.now
    timez.times {yield}
    res = yield
    t2 = (Time.now.to_f*1000).round
    t1 = (t1.to_f*1000).round
    $quiet, $log.mute_warn = quiet, mute_warn
    res = res.inspect
    puts "#{output ? "res: #{res.size > 1000 ? res[0...1000]+"…" : res}\n" : "size of res string: #{res.to_s.size}, "}one: #{Painter.gray '%0.4fms'%[(t2-t1).to_f/ts]}, total: #{Painter.gray "#{(t2-t1).to_f}ms"}"
  end
  
  module_function :timer
end