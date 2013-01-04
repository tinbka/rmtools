# encoding: utf-8
class BlackHole
  __init__

  # abc = BlackHole.new
  # (abc.first.get {|_| !_}.something << 'blah blah')[123].raise!
  # => #<BlackHole:0xb66367b0>
  # 
  # Think twice before use it. It may devour your code!
  def method_missing(m, *args)
    case m.to_s[-1,1]
    when '?'; false
    when '!'; nil
    when '='; args.first
    else self
    end
  end
  
  def b; false end
  
  if RUBY_VERSION < '1.9'
    undef id
  end
end