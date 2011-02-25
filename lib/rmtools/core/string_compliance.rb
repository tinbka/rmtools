# encoding: utf-8
class String

  if RUBY_VERSION < "1.9"
    def ord; self[0] end
    
    # TODO?
    # [g]sub[!] in ruby 1.8 takes the second arg which can operate \1, \2 etc keys as if it were MatchData parts
    # Though, in ruby 1.9 it ignores (without exception) the second arg and only pay attention to block. I can emulate ruby 1.8 second-arg-behaviour but
    # block passed to old method must be of the same context as that method's caller
    # in order to $~, $1 and such variables to work (and blocks with them are actualy used i.e. in Readline).
    # So now I'm afraid it useless to redefine these methods for 1.9 but I'll try some to hack it in C-ext
=begin
  else
    alias :sub19 :sub
    alias :sub19! :sub!
    alias :gsub19 :gsub
    alias :gsub19! :gsub!
    
    def sub a,b=nil,&c
      if b
        if b=~/\\\d/
          b = b.gsub19(/\\\d/) {|m| "\#$#{m[1]}"}
          sub19(a) {eval "\"#{b}\""}
        else sub19(a) {b} end
      else gsub19(a, &c) end
    end
    
    def sub! a,b=nil,&c
      if b
        if b=~/\\\d/
          b = b.gsub19(/\\\d/) {|m| "\#$#{m[1]}"}
          sub19!(a) {eval "\"#{b}\""}
        else sub19!(a) {b} end
      else sub19!(a, &c) end
    end

    def gsub a,b=nil,&c
      if b
        if b=~/\\\d/
          b = b.gsub19(/\\\d/) {|m| "\#$#{m[1]}"}
          gsub19(a) {eval "\"#{b}\""}
        else gsub19(a) {b} end
      else gsub19(a, &c) end
    end
    
    def gsub! a,b=nil,&c
      if b
        if b=~/\\\d/
          b = b.gsub19(/\\\d/) {|m| "\#$#{m[1]}"}
          p a
          gsub19!(a) {p "\"#{b}\""; p $~; p eval "\"#{b}\""; p eval "\"#{b}\""}
        else gsub19!(a) {b} end
      else gsub19!(a, &c) end
    end
=end
  end

end