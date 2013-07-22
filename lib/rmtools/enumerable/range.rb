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
# (1.9...4.1).include? 4 # => true, AND
# (1.9...4.1).include? 1 # => false, BUT
# [0,1,2,3,4,5][1.9...4.1] # => [1, 2, 3]
#
# A domain of the present extension is Set operations with ranges considered as lazy lists of integers.
# The present extension is solving the second problem, yet
# * saving the capability of a Range syntactic sugar;
# * does exactly extend and not modify the Range behaviour.
# These methods support only numeric ranges, it won't work with chars and datetime borders,
# though I'll make a support for the Date and Time in a future version.
class Range
  
  private
  def next_int(n)
    n.integer? || n.to_i == n ? n.to_i + 1 : n.ceil
  end
  
  def prev_int(n)
    n.integer? || n.to_i == n ? n.to_i - 1 : n.to_i
  end
  
  def int_end
    exclude_end? ? prev_int(last) : last.to_i
  end
  public
  
  # End inclusion need to universalize ranges for use in XRange list.
  # Considering the extension domain, one simply should not use "..." notation, but if such a range nevertheless appears as an argument, we reduce that to an operable one at the cost of a fractional accuracy
  # #include_end should not be coupled with #size and #empty? which have their own "..." handling
  # (0.9...1.3).include_end # => 0.9..1, BUT
  # (0.3...0.5).include_end # => 0.3..0
  def include_end
    exclude_end? ? first..prev_int(last) : self
  end
  
  def included_end
    exclude_end? ? prev_int(last) : last
  end
  
  # Represent a count of integers that range include and not real interval length
  # (0..0).size
  # => 1 (equivalent list of one 0)
  # (0...0).size 
  # => 0 (equivalent empty list)
  # (0.3..0.5).size 
  # => 0 (there is no integer between 0.3 and 0.5)
  # (0.9...1.1).size 
  # => 1 (equivalent list of one 1 which is between 0.9 and 1.1)
  # (2..1).size 
  # => 0 (such a range just does't make sense)
  def size
    [int_end - first.ceil + 1, 0].max
  end
  
  # Include any integer?
  def empty?
    size == 0
  end
  
  def b
    size != 0 && self
  end
  
  # Simplify a range to in-domain equivalent with integer edges.
  def integerize
    first.ceil..int_end
  end
  
  # Significant content of a range then.
  def integers
    integerize.to_a
  end
  alias :to_is :integers
  
  # Unfortunately, Range's start point can not be excluded, thus there is no *true inversion* of a range with included end.
  # Though, is this domain we can "integerize" range, then
  # -(1..2)
  # -(0.5..2.1)
  # (i.e. all excluding these indices: [1, 2])
  ### => XRange(-∞..0, 3..+∞)
  def -@
    XRange(-Inf..prev_int(first), (exclude_end? ? last.ceil : next_int(last))..Inf)
  end
  
  # Intersection
  def &(range)
    return range & self if range.is XRange
    fst = [first, range.first].max
    lst = [included_end, range.included_end].min
    fst > lst ? nil : fst..lst
  end
  
  # On the basis of #-@ for non-integers,
  # (0..3) - (1..2)
  # (0..3) - (0.5..2.1)
  ### => XRange(0..0, 3..3)
  def -(range)
    self & -range
  end
  
  alias :include_number? :include?
  # #include? corresponds with Ruby's default one, which considers a range as an interval
  # (0..1).include? 1.0
  # 1.in 0..1
  # => true
  # and (0...1.0).include? 1.0
  # => false
  def include?(number_or_range)
    if Numeric === number_or_range or String === number_or_range
      include_number? number_or_range
    elsif XRange === number_or_range
      number_or_range.include? self
    elsif Range === number_or_range
      include_number? number_or_range.first and include_number? number_or_range.last
    else
      #raise TypeError, "can not find #{number_or_range.class} in Range"
      # activerecord 4.0 tells it must not raise
      false
    end
  end
  
  # Does these ranges have at least one common point?
  # (0..1).x? 1..2
  # (1...2).x? 0..1
  # (0..3).x? 1..2
  # (1..2).x? 0..3
  # => true
  # (0..1.4).x? 1.5..2
  # (0...1).x? 1..2
  # (2..3).x? 0..1
  # => false
  def x?(range, pretend_not_exclude=false)
    return range.x? self if range.is XRange
    (range.last > first or ((!range.exclude_end? or pretend_not_exclude) and range.last == first)) and
    (range.first < last or ((!exclude_end? or pretend_not_exclude) and range.first == last))
  end
  alias :intersects? :x?
  
  # Union
  # (1..3) | (2..4)
  # => 1..4
  # (1...2) | (2..4)
  # => 1..4
  # (1..2) | (3..4)
  # => XRange(1..2, 3..4)
  # A result will be inadequate if any range is not integered and excludes end
  def |(range)
    return range | self if range.is XRange
    return XRange.new self, range if !x?(range, true)
    [first, range.first].min..[included_end, range.included_end].max
  end
  
  # Diff
  def ^(range)
    common = self & range
    self - common | range - common
  end
    
  def <=>(range) 
    (first <=> range.first).b || included_end <=> range.included_end
  end
  
  # Sum of integers in a range
  def sum
    last = included_end
    return (1..last).sum - (0..-first).sum if first < 0
    return 0 if last <= first
    last*(last+1)/2 - (1..first-1).sum
  end
  
  # minimum of monotone function definition interval
  def min(&fun)
    return first if !fun or yield first
    return unless yield last
    if yield(c = center)
      (first+1..c-1).min(&fun) || c
    else
      (c+1..last).min(&fun)
    end
  end 
  
  # maximum of monotone function definition interval
  def max(&fun)
    return last if !fun or yield last
    return unless yield first
    if yield(c = center)
      (c+1..last-1).max(&fun) || c
    else 
      (first..c-1).max(&fun)
    end
  end 
  
  def odds
    select {|i| i%2 != 0}
  end
  
  def evens
    select {|i| i%2 == 0}
  end
  
  # Average
  def center
    (first + included_end)/2 
  end
  alias :avg :center
  
  # Move range as interval right
  def >>(i)
    first + i .. included_end + i
  end
  
  # Move range as interval left
  def <<(i)
    first - i .. included_end - i
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
    "XRange(#{@ranges.join(', ').gsub('-Infinity', '-∞').gsub('Infinity', '+∞')})"
  end
  
end

