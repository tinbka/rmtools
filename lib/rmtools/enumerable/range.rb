# encoding: utf-8
unless defined? Inf
  Inf = 1.0/0
end

class Range
  
  # -(1.0..2.0)
  ### => XRange(-∞..1.0, 2.0..∞)
  # BUT
  # -(1..2)
  ### => XRange(-∞..0, 3..∞)
  # i.e. all excluding these: (0; 1], [1; 2], [2; 3)
  def -@
    self_begin = self.begin
    self_begin -= 1 if Integer === self_begin
    self_end = include_end.end
    self_end += 1 if Integer === self_end
    XRange(-Inf..self_begin, self_end..Inf)
  end
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
  
  
  # On the basis of #-@ for non-integers,
  # (0..1) - (1..2)
  ### => XRange(0..0)
  # (0..1.0) - (1..2)
  ### => XRange(0..0)
  # (0..1) - (1.0..2)
  ### => XRange(0..1.0)
  # (0..1.0) - (1.0..2)
  ### => XRange(0..1.0)
  def -(range)
    self & -range
  end
  
  def ^(range)
    common = self & range
    self - common | range - common
  end
  
  # Statement about non-integers is made with presumption that float presentation of number is a neighborhood of it.
  # Thus, "1.0" lies in the neighborhood of "1"; [0..1.0] is, mathematically, [0; 1) that not intersects with (1; 2]
  # and thereby (0..1.0).x?(1.0..2) should be false, although (0..1).x?(1..2) should be true
  def x?(range)
    return range.x? self if range.is XRange
    range_end = range.include_end.end
    self_end = self.include_end.end
    if self_end < range_end
      if Integer === self_end and Integer === range.begin
        self_end >= range.begin
      else
        self_end > range.begin
      end
    else
      if Integer === self.begin and Integer === range_end
        range_end >= self.begin
      else
        range_end > self.begin
      end
    end
  end
  alias :intersects? :x?
    
  def <=>(range) 
    (self.begin <=> range.begin).b || self.include_end.end <=> range.include_end.end 
  end
  
  def include_end
    exclude_end? ? self.begin..(self.end - 1) : self 
  end
  
  def center
    (first + last + (!exclude_end?).to_i)/2 
  end
  
  def part(i, j) 
    first + (i-1)*size/j .. first - 1 + i*size/j unless i < 1 or j < 1 or j < i 
  end
  
  def size
    (last - first).abs + (!exclude_end?).to_i 
  end
  
  # Irrespective of include_end to be able to determne ranges created in any way
  def b
    self.begin != self.end && self
  end
  
  def div(n)
    unless n < 1
      rarray = []
      j = self.begin
      iend = include_end.end
      rarray << (j..(j+=n)-1) until j+n > iend
      rarray << (j..iend)
    end
  end
  
  def /(i)
    part 1, i
  end
  
  def >>(i)
    self.begin + i .. include_end.end + i
  end
  
  def <<(i)
    self.begin - i .. include_end.end - i
  end
  
  def of(ary) 
    ary[self] 
  end
  
  def odds
    select {|i| i%2 != 0}
  end
  
  def evens
    select {|i| i%2 == 0}
  end
  
  def sum
    ie = include_end.end
    return (1..ie).sum - (0..-self.begin).sum if self.begin < 0
    return 0 if ie < self.begin
    ie*(ie+1)/2 - (1..self.begin-1).sum
  end
  
  # monotone function definition interval min/max border
  def min(&fun)
    return first if yield first
    return unless yield last
    if yield(c = center)
      (first+1..c-1).min(&fun) || c
    else
      (c+1..last).min(&fun)
    end
  end 
  
  def max(&fun)
    return last if yield last
    return unless yield first
    if yield(c = center)
      (c+1..last-1).max(&fun) || c
    else 
      (first..c-1).max(&fun)
    end
  end 
  
end

class XRange
  attr_accessor :ranges
  __init__
  
  def initialize *args
    if (str = args[0]).is String
      str.scan(/([&|v\^])?((-?\d+)\.\.(\.)?(-?\d+))/).each {|s|
        s[2], s[4] = s[2].to_i, s[4].to_i
        r = s[3] ? s[2]..s[4]-1 : s[2]..s[4]
        @ranges = case s[0]
                          when '&', '^'; intersect r
                          when '|', 'v'; union r
                          else [r]
                        end
      }
      @ranges.sort!
    else
      0.upto(args.sort!.size-2) {|i| args[i,2] = [nil, args[i]|args[i+1]] if args[i].x? args[i+1]}
      @ranges = args.compact.include_ends
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
  
  def -@
    @ranges.map {|r| -r}.foldl(:&)
  end
  
  def -(range)
    self & -range
  end
  
  def ^(range)
    common = self & range
    self - common | range - common
  end
  
  def x?(range)
    @ranges.any? {|r| range.x? r}
  end
  alias :intersects? :x?
  
private
  
  def intersect(range)
    @ranges.map {|r| r&range}.compact
  end
  
  def union(range)
    changed = (rs = @ranges.map {|r| (r.x?range) ? r|range : r}) != @ranges
    changed ? rs : rs << range
  end
    
  include Enumerable
  
public
  def each(&b) 
    @ranges.each {|r| r.each &b} 
  end
  
  def of(ary) 
    @ranges.foldl(:+) {|r| ary[r]} 
  end
  
  def empty?
    @ranges.empty?
  end
  
  def include?(number_or_range)
    @ranges.find {|r| r.include?(number_or_range)}
  end
  
  def begin
    @ranges[0].begin
  end
  
  def end
    @ranges[-1].end
  end
  
  def size
    @ranges.sum {|r| r.size}
  end
  
  def b
    size != 0 && self
  end
  
  def div(n)
    unless n < 1
      i = 0
      rarray = []
      j = @ranges[0].begin
      while range = @ranges[i]
        if j+n > range.end
          rarray << (j..range.end)
          i += 1
          j = @ranges[i].begin if @ranges[i]
        else
          rarray << (j..(j+=n)-1)
        end
      end
      rarray
    end
  end
  
  def inspect
    "XRange(#{@ranges.join(', ').gsub('Infinity', '∞')})"
  end
  
end

