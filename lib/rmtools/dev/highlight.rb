# encoding: utf-8
RMTools::require 'console/coloring'

module RMTools
    
  def highlighted_line(file, line)
    if defined? SCRIPT_LINES__ and SCRIPT_LINES__[file]
      "   >>   #{Painter.green((SCRIPT_LINES__[file][line.to_i - 1] || "<line #{line} is not found> ").chop)}"
    else
      file = Readline::TEMPLOG if file == '(irb)' and defined? Readline::TEMPLOG
      if File.file? file
        line_read = read_lines(file, line.to_i) || "<line #{line} is not found> "
        if defined? SCRIPT_LINES__
          SCRIPT_LINES__[file] = IO.readlines(file)
          highlighted_line file, line
        else
          "   #{Painter.cyan '>>'}   #{Painter.green line_read.chop}" 
        end
      end
    end
  end
    
  module_function :highlighted_line
end
  
class Proc
  
  def inspect
    "#{to_s}#{@string ? ': '+Painter.green(@string) : source_location && ": \n"+RMTools.highlighted_line(*source_location)}"
  end
  
end