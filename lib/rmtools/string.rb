# encoding: utf-8
class String
  if !method_defined? :/
    alias :/ :split 
  end
  
  def inline
    count("\n") == 0
  end
  
  def <<(str)
    concat str.to_s
  end
  
  # %{blah blah
  #  wall of text in the interpreter
  # oh shi~ may be we should
  # save this into variable
  # } >> (str='') 
  # ok, easily saved to variable
  def >>(str)
    str.replace(self + str)
  end
  
  def find_with_offsets text, offset
    index = index(text)
    start = [0, index - offset].max
    _end = index + text.size
    [self[start...index], text, self[_end, offset]]
  end
  
  def div(dvsr, includesplitter=1, reportheaders=nil)
    return lendiv dvsr if dvsr.kinda Fixnum
    a = split(dvsr)
    return a if !includesplitter and !reportheaders
    skan = nil
    case dvsr
      when String
        a = (1...a.size).map {|i| dvsr+a[i]}.unshift a[0] if includesplitter
      when Regexp
        skan = scan(dvsr).unshift ''
        a = (0...a.size).map {|i| skan[i].to_s+a[i]} if includesplitter
    end
    (reportheaders and skan) ? [a, skan] : a
  end
  
  def rdiv(dvsr, includesplitter=1, reportheaders=nil)
    return lendiv dvsr if dvsr.kinda Fixnum
    a = split(dvsr)
    return a if !includesplitter and !reportheaders
    skan = nil
    case dvsr
      when String
        a = (0...a.size).map {|i| a[i]+dvsr} if includesplitter
      when Regexp
        skan = scan(dvsr)
        a = (0...a.size).map {|i| a[i]+skan[i]} if includesplitter
    end
    (reportheaders and skan) ? [a, skan] : a
  end
  
  def lendiv(len)
    return [self] if len <= 0
    str = dup
    arr = []
    while str.b
      arr << str.slice!(0, len)
    end
    arr
  end
  
  def split_to_lines(maxlen, charsize=nil, no_blanks=false, strips=true)  
    raise Exception, "Can't break text with maxlen = #{maxlen}" if maxlen < 1
    a = split("\n")
    charsize ||= a[0].cyr? ? 2 : 1
    a.map {|string| string.strip.split_to_blocks(maxlen*charsize, nil, false, no_blanks, strips)}.flatten*"\n"
  end
  
  def split_to_blocks(maxlen, terminator=nil, strict_overhead=true, no_blanks=true, strips=false)
    raise Exception, "Can't break text with maxlen = #{maxlen}" if maxlen < 1
    blocks = []
    term_re = /[^#{terminator}]+\z/ if terminator and terminator != :syntax
    return [self] if size <= maxlen
    words, buf = split(strips ? ' ' : / /), nil
    while words.b or buf.b
      if terminator and blocks.b and (buf_add = if terminator == :syntax
               blocks[-1].split_by_syntax maxlen, buf.size
        else blocks[-1][term_re]
        end.b)
        if buf_add == blocks[-1]
               blocks.pop
        else blocks[-1] = blocks[-1][0...-buf_add.size]
        end
        buf = buf_add + buf
      end
      blocks << ''
      if buf
        blocks[-1] << buf
        buf = nil
      end
      while words.b
        buf = words.shift + ' '
        break if blocks[-1].size + buf.size - 1 > maxlen
        blocks[-1] << buf
        buf = nil
      end
    end
    blocks.reject! &:empty? if no_blanks
    blocks.strips! if strips
    blocks.each {|b| raise Exception, "can't split string by #{terminator} to blocks with max length = #{maxlen}" if b.size > maxlen} if strict_overhead
    blocks
  end
  
  RMTools::URL_RE = %r{^((?:([^:]+)://)#{	              #  ( protocol
                                   }([^/:]*(?::(\d+))?))?#{	    #  root[:port] )
                                   }((/[^?#]*?(?:\.(\w+))?)#{	#  ( path[.fileext]
                                   }(?:\?(.*?))?)?#{	              #  [?query params] )   
                                   }(?:#(.+))?#{	                  #  [ #anchor ]
                                 }$}	  unless defined? RMTools::URL_RE
  def parseuri
    m = match RMTools::URL_RE
    !m || m[0].empty? ?
      {  'href'	        => self  } : 
      {	'href'	      => self,
          'root'	      => m[1],
          'protocol'	=> m[2],
          'host'	      => m[3], 
          'port'	      => m[4] ? m[4].to_i : 80,
          'fullpath'	=> m[5] || '/',
          'pathname'	=> m[5] || '/',
          'path'	      => m[6] || '',
          'ext'	        => m[7],
          'query'	      => m[8] && m[8].to_hash(false),
          'anchor'	    => m[9] }
  end
  
  def utf(from_encoding)
    Iconv.new('UTF-8', from_encoding).iconv(self)
  end
  
  def utf!(from_encoding)
    replace utf from_encoding
  end
  
  def bytes
    arr = []
    each_byte {|b| arr << "\\x#{b.hex}"}
    arr
  end
  
  def to_re(esc=false)
    Regexp.new(esc ? Regexp.escape(self) : self)
  end

  def lchomp(match)
    if index(match) == 0
      self[match.size..-1]
    else
      self.dup
    end
  end

  def lchomp!(match)
    if index(match) == 0
      self[0...match.size] = ''
      self
    end
  end
  
  def rsplit(splitter=$/, qty=0)
    reverse.split(splitter, qty).reverse.reverses
  end
  
  def until(splitter=$/)
    split(splitter, 2)[0]
  end
  alias :till :until
  
  def after(splitter=$/)
    split(splitter, 2)[1]
  end
  
  def bump_version(splt='.')
    re = /(?:(\d*)#{Regexp.escape splt})?/
    s = File.split self
    s[0] == '.' ?
      s[1].reverse.sub(re) {$1?"#{$1.to_i+1}#{splt}":"1#{splt}"}.reverse :
      File.join(s[0], s[1].reverse.sub(re)  {$1?"#{$1.to_i+1}#{splt}":"1#{splt}"}.reverse)
  end
  alias :next_version :bump_version
  
  def bump!(splt='.')
    replace bump_version splt
  end
  
if RUBY_VERSION < "1.9"
  def ord; self[0] end
else
  # BUGFIX?
  alias :sub19 :sub
  alias :sub19! :sub!
  alias :gsub19 :gsub
  alias :gsub19! :gsub!
  
  def sub! a,b=nil,&c
    if b
      if b=~/\\\d/
        b = b.sub19!(/\\\d/) {|m| "\#{$#{m[1,1]}}"}
        sub19!(a) {eval "\"#{b}\""}
      else sub19!(a) {b} end
    else sub19! a,&c end
  end

  def sub a,b=nil,&c
    if b
      if b=~/\\\d/
        b = b.sub19(/\\\d/) {|m| "\#{$#{m[1,1]}}"}
        sub19(a) {eval "\"#{b}\""}
      else sub19(a) {b} end
    else sub19 a,&c end
  end
end

  def to_limited len=100
    LimitedString.new self, len
  end
  
protected
  def split_by_syntax(maxlen, buflen=0)
    len, add = maxlen - buflen, nil
    [/[^.?!]+\z/, /[^;]+\z/, /[^\n]+/, /\S+\z/, /[^。]+z/, /[^、]+z/].each {|t|
      if !(add = self[t]) or add.size <= len
        return add
      end
    }
    add
  end
    
end
  
class Indent < String
  attr_reader :indent

  def initialize(indent='  ')
    @indent = indent
    super ''
  end
  
  def +@
    self << @indent
  end
  
  def -@
    self.chomp! @indent
  end
  
  def i(&block)
    +self
    res = yield
    -self
    res
  end

end

class Regexp
  
  def | re
    Regexp.new(source+'|'+re.source, options | re.options)
  end
  
  def in string
    string =~ self
  end
  
end