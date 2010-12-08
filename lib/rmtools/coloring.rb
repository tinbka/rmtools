# encoding: utf-8
module RMTools

    class Coloring
        __init__
        method_defined? :b and undef_method :b
        method_defined? :p and undef_method :p
        
        if !defined? ::BOLD
            BOLD = 1
            UNDERLINE = 4
            GRAYBG = 5
            BOLDBG = 7
            
            KEY = BLACK = 30
            RED = 31
            GREEN = 32
            YELLOW = 33
            BLUE = 34
            PURPLE = 35
            CYAN = 36
            GRAY = 37
            
            Colors = {:black => 30, :red => 31, :green => 32, :yellow => 33, :blue => 34, :purple => 35, :cyan => 36, :gray => 37,
                        :k => 30, :r => 31, :g => 32, :y => 33, :b => 34, :p => 35, :c => 36
                  }.unify_strs
            Effects = {:bold => 1, :underline => 4, :graybg => 5, :boldbg => 7,
                          :b => 1, :u => 4, :gbg => 5, :bbg => 7
                  }.unify_strs   end
        
        def paint(str, num=nil, effect=nil)
            # default cmd.exe cannot into ANSI
            return str if ENV['ComSpec'] =~ /cmd(.exe)?$/
            num = Colors[num] if num.is String
            effect = Effects[effect] if effect.is String
            if num and effect
                "\e[#{effect};#{num}m#{str}\e[m"
            elsif effect
                "\e[#{effect}m#{str}\e[m"
            elsif num
                "\e[#{num}m#{str}\e[m"
            else str    
            end 
        end
        
        def method_missing(m, str)
            paint str, *(m.to_s/"_")
        end
        
        def clean str
            str.gsub(/\e\[.*?m/, '')
        end
    
    end
  
    Painter = Coloring.new
    ['sub', 'gsub', 'sub!', 'gsub!'].each {|m| Coloring.module_eval "
      def #{m.sub 'sub', 'hl'} str, pattern, color=:red_bold
          str.#{m}(pattern) {|word| send color, word}
      end
     "
        module_eval "
      def #{m.sub 'sub', 'hl'} str, pattern, color=:red_bold
          str.#{m}(pattern) {|word| Painter.send color, word}
      end
     "
  #      module_function m.to_sym
    }
  
end

class String
  
  def find_hl(pat, range=1000) idx = case pat
    when String;   index pat
    when Regexp; self =~ pat
    else raise TypeError, "pattern must be string or regexp"
    end
    puts RMTools.ghl(self[[idx-range, 0].max, 2*range], pat)
  end
  
end
