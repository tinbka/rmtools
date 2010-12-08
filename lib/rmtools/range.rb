# encoding: utf-8
class Range
  
  def &(range)
    return range&self if range.is XRange
    beg = [self.begin, range.begin].max
    end_ = [self.include_end.end, range.include_end.end].min
    beg > end_ ? nil : beg..end_
  end
  
  def |(range)
    return range|self if range.is XRange
    range = range.include_end
    self_ = self.include_end
    return XRange.new self, range if !x?(range)
    [self.begin, range.begin].min..[self_.end, range.end].max
  end
  
  def x?(range)
    range_end = range.include_end.end
    self_end = self.include_end.end
    if self_end < range_end
      self_end >= range.begin - (self_end.kinda Integer and range.begin.kinda Integer).to_i
    else
      range_end >= self.begin - (self.begin.kinda Integer and range_end.kinda Integer).to_i
    end
  end
    
  def <=>(range) (self.begin <=> range.begin).b || self.include_end.end <=> range.include_end.end end
  
  def include_end() exclude_end? ? self.begin..(self.end - 1) : self end
  
  def center() (first + last + (!exclude_end?).to_i)/2 end
  
  def part(i, j) first+(i-1)*size/j...first+i*size/j unless i < 1 or j < 1 or j < i end
  
  def size() last - first + (!exclude_end?).to_i end
  
  def /(i) first...size/i end
  
  def from(ary) ary[self] end
  
end

class XRange
  attr_accessor :ranges
  __init__
  
  def initialize *args
    if (str = args[0]).is String
      str.scan(/([&|])?((-?\d+)\.\.(\.)?(-?\d+))/).each {|s|
        s[2], s[4] = s[2].to_i, s[4].to_i
        r = s[3] ? s[2]...s[4] : s[2]..s[4]
        @ranges = case s[0]
                          when '&', '^'; intersect r
                          when '|', 'v'; union r
                          else [r]
                        end
      }
      @ranges.sort!
    else
      0.upto(args.sort!.size-2) {|i| args[i,2] = [nil, args[i]|args[i+1]] if args[i].x? args[i+1]}
      @ranges = args.compact
    end
  end
  
  def &(range)
    if range.is Range
      XRange.new *intersect(range)
    else
      @ranges.map {|r| range & r}.foldl(:|)
    end
  end
  
  def |(range)
    if range.is Range
      XRange.new *union(range)
    else
      @ranges.each {|r| range |= r}
      range
    end
  end
  
  def intersect(range)
    @ranges.map {|r| r&range}.compact
  end
  
  def union(range)
    changed = (rs = @ranges.map {|r| (r.x?range) ? r|range : r}) != @ranges
    changed ? rs : rs << range
  end
    
  include Enumerable
  
  def each(&b) @ranges.each {|r| r.each &b} end
  
  def from(ary) @ranges.foldl(:+) {|r| ary[r]} end
  
end

