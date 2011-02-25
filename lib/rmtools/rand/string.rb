# encoding: utf-8
RMTools::require 'lang/ansi'

module RMTools
  begin
    require 'securerandom'
    SecureRandom.random_bytes
    Urandom = true
  rescue
    Urandom = false
  end
  Numbers = '0123456789'
  Chars = 'abcdefghijklmnopqrstuvwxyz'
  Alphanum = Chars + Chars.upcase + Numbers
  ASCII_readable = '!"#$%&\'()*+,-./[\]^_`{|}~:;<=>?@ ' + Alphanum
  RuChars = UTF2ANSI[Cyrillic::RU_LETTERS[0]]
  RuAlphanum = UTF2ANSI[Cyrillic::RU_LETTERS.join] + Numbers
  
  def randstr(len=8, what=:alphanum)
    s = ''
    res = case what
      when :bytes, :binary
        if Urandom
          SecureRandom.random_bytes len
        else
          len.times {s.concat rand 256}; s
        end
      when :ascii
        if Urandom
          SecureRandom.random_bytes(len*3).tr("^ -~", '')[0...len]
        else
          len.times {s.concat ASCII_readable[rand 95].ord}; s
        end
      when :char
        if Urandom
          res = SecureRandom.base64(len*2).tr("^a-z", '')[0...len]
        else
          len.times {s.concat Chars[rand 26].ord}; s
        end
      when :alphanum
        if Urandom
          res = SecureRandom.base64(len).tr("+/=", '')[0...len]
        else
          len.times {s.concat Alphanum[rand 62].ord}; s
        end
      when :num, :digit
        if Urandom
          res = SecureRandom.hex(len).tr("^0-9", '')[0...len]
        else
          len.times {s.concat Numbers[rand 10].ord}; s
        end
      when :hex
        if Urandom
          res = SecureRandom.hex len/2
        else
          len.times {s.concat Numbers[rand 10].ord}; s
        end
      when :cyr, :cyrilic
        if Urandom
          res = ANSI2UTF[SecureRandom.random_bytes(len*8).tr("^\270\340-\377", '')[0...len]]
        else
          len.times {s.concat RuChars[rand 33].ord}; ANSI2UTF[s]
        end
      when :cyr_full, :cyr_alphanum
        if Urandom
          res = ANSI2UTF[SecureRandom.random_bytes(len*3.5).tr("^0-9\250\270\340-\377\300-\337", '')[0...len]]
        else
          len.times {s.concat RuAlphanum[rand 76].ord}; ANSI2UTF[s]
        end
        
      when Symbol then raise ArgumentError, "invalid symbol :#{what}, valid symbols are
        :bytes, :binary, :char, :alphanum, :num, :digit, :hex, :cyr, :cyrilic, :cyr_full, :cyr_alphanum"
      when String then res = randstr(len*10, :bytes).tr("^#{what}", '')
      else raise ArgumentError, "invalid argument #{what}, class #{(what.class)}"
    end
    res << randstr((len-res.size)*2, what) while res.size < len
    res[0...len]
  end
  
  module_function :randstr
end

class String
  
  def self.rand(*args)        
    RMTools.randstr(*args)
  end

  def rand(chsize=1)
    self[Kernel.rand(size*chsize), chsize]
  end

  def randsubstr(chsize=1)
    (a = Kernel.rand(size*chsize)) > (b = Kernel.rand(size*chsize)) ? self[b..a] : self[a..b]
  end

  def randsample(qty=Kernel.rand(size))
    split('').randsample(qty)
  end
  
end