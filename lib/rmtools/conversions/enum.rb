# encoding: utf-8

module Enumerable
  
  # Simple http stringifying:
  # {'a'=>10, 'b'=>20}.urlencode
  # => "a=10&b=20"
  # Stringifies hashes with multi-value values:
  # {'a'=>'10&20&30'}.urlencode
  # or
  # {'a'=>[10, 20, 30]}.urlencode
  # => "a=10&a=20&a=30"
  # Stringifies hashes with multi-value keys as well:
  # {['a', 'b']=>[10, 20]}.urlencode
  # => "a=10&a=20&b=10&b=20"
  # Stringifies hashes with hash-value values:
  # {'a'=>{0=>10, 'b'=>{'c'=>20, 'd'=>30}}}.urlencode
  # => "a[0]=10&a[b][c]=20&a[b][d]=30"
  
  # TODO: deal with it
  def urlencode
    map {|k, v| next if !v
      k, v = k.to_s, v.to_s
      if v =~ /&/
        v = v/'&'
        v.map {|val| "#{CGI.escape(k)}=#{CGI.escape(val)}"} * '&'
      elsif k =~ /&/
        k = k/'&'
        k.map {|key| "#{CGI.escape(key)}=#{CGI.escape(v)}"} * '&'
      else
        "#{CGI.escape(k)}=#{CGI.escape(v)}" 
      end
    } * '&'
  end
    
end