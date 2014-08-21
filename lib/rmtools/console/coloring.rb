# encoding: utf-8
RMTools::require 'enumerable/hash'

module RMTools

  class Painter
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
            
      Colors = {:black => 30, :red => 31, :green => 32, :yellow => 33, :blue => 34, :purple => 35, :cyan => 36, :gray => 37, :pink => [35, 1], :violet => [35, 1],
                    :k => 30, :r => 31, :g => 32, :y => 33, :b => 34, :p => 35, :c => 36, :w => [37, 1], :v => [35, 1]
                  }.unify_keys
      Effects = {:bold => 1, :underline => 4, :graybg => 5, :boldbg => 7,
                      :b => 1, :u => 4, :gbg => 5, :bbg => 7
                  }.unify_keys   
    end
                
    class << self    
      method_defined? :b and undef_method :b
      method_defined? :p and undef_method :p  
      
      def demo(str, pattern=nil)
        %w[black red green yellow blue purple cyan gray].product(%w[bold underline graybg boldbg]).each {|color, effect|
          if pattern
            puts ghl(str, pattern, "#{color}_#{effect}")
          else
            puts paint(str, transparent, color, effect)
          end
        }
      end
      
      def paint(str, transparent, num=nil, effect=nil)
        # default cmd.exe cannot into ANSI
        str = str.to_s
        return str if ENV['ComSpec'] =~ /cmd(.exe)?$/
        if num.is String
          num = Colors[num]
          if !num
            effect = Effects[num]
          elsif num.is Array
            num, effect = num
          end
        end
        effect = Effects[effect] if effect.is String
        if num and effect
          str = str.gsub("\e[m", "\e[m\e[#{effect};#{num}m") if transparent
          "\e[#{effect};#{num}m#{str}\e[m"
        elsif effect
          str = str.gsub("\e[m", "\e[m\e[#{effect}m") if transparent
          "\e[#{effect}m#{str}\e[m"
        elsif num
          str = str.gsub("\e[m", "\e[m\e[#{num}m") if transparent
          "\e[#{num}m#{str}\e[m"
        else str    
        end 
      end
      
      # Without +transparent+ Painter stops coloring once it find colored substring
      #     puts "words have one #{Painter.red_bold 'highlighted'} among them"
      # <default>words have one <red>highlighted</red> among them</default>
      #     puts Painter.gray "words have one #{Painter.red_bold 'highlighted'} among them"
      # <gray>words have one </gray><red>highlighted</red><default> among them</default>
      #     puts Painter.gray "words have one #{Painter.red_bold 'highlighted'} among them", true
      # <gray>words have one <red>highlighted</red> among them</gray>
      #
      # Actually, transparent coloring is slower
      def method_missing(m, str, transparent=false)
        paint str, transparent, *(m.to_s/"_").bs
      end
          
      def clean str
        str.gsub(/\e\[[\d;]*m/, '')
      end

      ['sub', 'gsub', 'sub!', 'gsub!'].each {|m| 
        class_eval %{
      def #{m.sub'sub','hl'} str, pattern, color=:red_bold
        pattern = pattern.to_s unless pattern.is Regexp
        str.#{m} pattern do |word|
          if str[/^\\e\\[(\\d+(;\\d+)?)/]
            "\\e[m\#{send(color, word)}\\e[\#$1m"
          else
            send(color, word)
          end
        end
      end
      }
        String.class_eval %{
      def #{m.sub'sub','hl'} pattern, color=:red_bold
        Painter.#{m.sub'sub','hl'} self, pattern, color
        #{'self' if '!'.in m}
      end
      }
      }
      
    end
    
  end
  
end
