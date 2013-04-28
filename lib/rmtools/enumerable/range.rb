# encoding: utf-8
unless defined? Inf
  Inf = 1.0/0
end

# Range in Ruby can have at least 2 meanings:
# 1) interval of real numbers
# (0...2).include? 1.6 # => true
# 2) lazy list of array indices (included integers):
# [0,1,2,3,4,5][1..4] # => [1, 2, 3, 4]
#
# There is some basic problems.
# 1) For the first way of using, Range doesn't have Set operations. Further more Range can not be complex.
# There is "intervals" gem that partially solves these problems, but it's arithmetic is not Set compatible:
# -Interval[1,2] # => Interval[-2, -1]
# 2) Hardly we can use Range second way, when it defined by a floating point numbers:
# [0,1,2,3,4,5][1.9..4] # => [1, 2, 3, 4]
# (1.9...4.1).include? 4 # => true, BUT
# [0,1,2,3,4,5][1.9...4.1] # => [1, 2, 3]
#
# This extension does not solve both problems, because I wanted to save the usability of Range syntactic sugar. Though, I want to make new one that shall solve these.
# So far, the present extension applies Set operations to ranges considered as lists of contained integers. 
# It means: 
# (x..y) equivalent (x...y+0.5) equivalent (x...y+1) equivalent [x, x+1, ..., y]
# Note quantity of dots (end exclusion)
class Range
  
  def include_end
    exclude_end? ? first..(last.integer? ? last - 1 : last.to_i) : self 
  end
  
  # (0..0).size # => 1 (equivalent list of one zero)
  # (0...0).size # => 0 (equivalent empty list)
  def size
    (include_end.last - first).abs + 1
  end
  
  def empty?
    size == 0
  end
  
  def b
    size != 0 && self
  end
  
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
  
  alias :include_number? :include?
  # This function corresponds with ruby's default one in that we consider any number as a point on a segment.
  # Thus, any of these 0..1, 0..1.0
  # would return true as for 1 so as for 1.0
  def include?(number_or_range)
    if Numeric === number_or_range
      include_number? number_or_range
    elsif XRange === number_or_range
      number_or_range.include? self
    else
      include_number? number_or_range.begin and include_number? number_or_range.end
    end
  end
  
  def |(range)
    return range|self if range.is XRange
    range = range.include_end
    self_ = self.include_end
    return XRange.new self, range if !x?(range)
    [self.begin, range.begin].min..[self_.end, range.end].max
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
  
  def center
    (first + include_end.last)/2 
  end
  
  def part(i, j) 
    first + (i-1)*size/j .. first - 1 + i*size/j unless i < 1 or j < 1 or j < i 
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
  
  # minimum of monotone function definition interval
  def min(&fun)
    return first if yield first
    return unless yield last
    if yield(c = center)
      (first+1..c-1).min(&fun) || c
    else
      (c+1..last).min(&fun)
    end
  end 
  
  # maximum of monotone function definition interval
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
      @ranges.map {|r| range & r}.fold(:|)
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
    @ranges.map {|r| -r}.fold(:&)
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
    @ranges.sum_of(ary)
  end
  
  def size
    @size ||= @ranges.sum_size
  end
  
  def empty?
    @empty ||= @ranges.any? {|r| !r.empty?}
  end
  
  def b
    !empty? && self
  end
  
  def include?(number_or_range)
    @ranges.find_include?(number_or_range)
  end
  
  def begin
    @begin ||= @ranges.first && @ranges.first.begin
  end
  
  def end
    @end ||= @ranges.last && @ranges.last.end
  end
  
  alias :to_a_first :first
  def first(count=nil)
    count ? to_a_first(count) : self.begin
  end
    
  def last(count=nil)
    count ? to_a.last(count) : self.end
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

