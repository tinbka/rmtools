# encoding: utf-8
class BlackHole

  # abc = BlackHole.new
  # (abc.first.get {|_| !_}.something << 'blah blah')[123].raise!
  # => #<BlackHole:0xb66367b0>
  # 
  # Think twice before use it. It may devour your code!
  def method_missing(*)
    BlackHole.new
  end
  
end