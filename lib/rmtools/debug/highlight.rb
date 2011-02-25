# encoding: utf-8
RMTools::require 'console/coloring'

module RMTools
    
  def highlighted_line(file, line)
    if defined? SCRIPT_LINES__ and SCRIPT_LINES__[file]
      "   >>   #{Painter.green SCRIPT_LINES__[file][line.to_i - 1].chop}"
    else
      file = Readline::TEMPLOG if file == '(irb)' and defined? Readline::TEMPLOG
      "   #{Painter.cyan '>>'}   #{Painter.green read_lines(file, line.to_i).chop}" if File.file? file
    end
  end
    
  module_function :highlighted_line
end
  
class Proc
  
  def inspect
    "#{str=to_s}: #{@string ? Painter.green(@string) : "\n"+RMTools.highlighted_line(*source_location)}"
  end
  
end