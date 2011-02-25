# encoding: utf-8
require 'cgi'

module Enumerable
  
  # Simple http stringifying. Also stringifies multi-value hashes
  # {'a'=>'10&20&30'}.urlencode
  # => "a=10&a=20&a=30"
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