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
# instead of 
# # => Interval[[-Inf, -2], [-1, +Inf]]
# 2) Hardly we can use Range second way, when it defined by non-integers:
# [0,1,2,3,4,5][1.9..4] # => [1, 2, 3, 4]
# (1.9...4.1).include? 4 # => true, BUT
# [0,1,2,3,4,5][1.9...4.1] # => [1, 2, 3]
#
# This extension leaves the first problem for a purpose of solving the second, saving the capability of a Range syntactic sugar. The present extension applies Set operations to ranges considered as lists of contained integers. 
# It means: 
# (x..y) equivalent (x...y+0.5) equivalent (x...y+1) equivalent [x, x+1, ..., y]
# Note quantity of dots (end exclusion)
class Range
  
  def included_end
    exclude_end? ? last.integer? ? last - 1 : last.to_i : last
  end
  
  def include_end
    exclude_end? ? first..included_end : self 
  end
  
  # Since it's not represent an interval...
  # (0..0).size # => 1 (equivalent list of one zero)
  # (0...0).size # => 0 (equivalent empty list)
  # There is no empty ranges with end included (since it includes at least an end, right?)
  def size
    exclude_end? ? (last - first).abs : (last - first).abs+1
  end
  
  def empty?
    exclude_end? && last == first
  end
  
  def b
    !empty? && self
  end
  
  # Let significant content of a range used this way be:
  def integers
    (first.ceil..included_end).to_a
  end
  alias :to_is :integers
  
  # -(1..2)   
  # -(0.5..2.1)
  # i.e. all excluding these lazy indices: [1, 2]
  ### => XRange(-∞..0, 3..∞)
  def -@
    XRange(-Inf..first.ceil-1, (exclude_end? && last.integer? ? last : last.to_i+1)..Inf)
  end
  
  def &(range)
    return range & self if range.is XRange
    fst = [first, range.first].max
    lst = [included_end, range.included_end].min
    fst > lst ? nil : fst..lst
  end
  
  # On the basis of #-@ for non-integers,
  # (0..3) - (0.5..2.1)
  # (0..3) - (1..2)
  ### => XRange(0..0, 3..3.0)
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
      include_number? number_or_range.first and include_number? number_or_range.last
    end
  end
  
  def x?(range)
    return false if empty?
    return range.x? self if range.is XRange
    range_end = range.included_end
    if range_end < range.first
      return x?(range_end..range.first)
    end
    self_end = included_end
    if self_end < first
      return (first..self_end).x?(range)
    end
    case self_end <=> range_end
    when -1
      self_end >= range.first
    when 1
      first <= range_end >= first
    else
      true
    end
  end
  alias :intersects? :x?
  
  def |(range)
    return range | self if range.is XRange
    range = range.include_end
    self_ = self.include_end
    return XRange.new self, range if !x?(range)
    [self.begin, range.begin].min..[self_.end, range.end].max
  end
  
  def ^(range)
    common = self & range
    self - common | range - common
  end
    
  def <=>(range) 
    (first <=> range.first).b || included_end <=> range.included_end
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
      @ranges.map {|r| range & r}.foldl(:|) || XRange.new
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
    @ranges.map {|r| -r}.foldl(:&) || XRange.new(-Inf..+Inf)
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
  
  # XRange doesn't support ranges with end excluded, so it's empty only if contains nothing
  def empty?
    @ranges.empty?
  end
  
  def b
    !@ranges.empty? && self
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

