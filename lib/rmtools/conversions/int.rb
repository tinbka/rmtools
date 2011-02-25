# encoding: utf-8
class Integer
  
    def kb;  self*1024 end
    def mb; self*1048576 end
    def gb;  self*1073741824 end

    def to_timestr(t=nil)
      if t
        if t.in [:minutes, :min, :m]
          "#{self/60} minutes"
        elsif t.in [:hours, :h]
          "#{self/3600} hours"
        elsif t.in [:days, :d]
          "#{self/86400} days"
        end
      elsif self < 60
        "#{self} seconds"
      elsif self < 3600
        "#{self/60} minutes"
      elsif self < 86400
        "#{self/3600} hours"
      else
        "#{self/86400} days"
      end
    end
    
    def bytes(t=nil)
      if t
        if :kb == t
          "%.2fKB"%[to_f/1024]
        elsif :mb == t
          "%.2fMB"%[to_f/1048576]
        elsif :gb == t
          "%.2fGB"%[to_f/1073741824]
        end
      elsif self < 1024
        "#{self}B"
      elsif self < 1048576
        "%.2fKB"%[to_f/1024]
      elsif self < 1073741824
        "%.2fMB"%[to_f/1048576]
      else
        "%.2fGB"%[to_f/1073741824]
      end
    end
    
  end