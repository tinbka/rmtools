module RMTools
  begin
    SecureRandom.random_bytes
    UrandomEnabled = true
  rescue
    UrandomEnabled = false
  end
    
  Numbers = '0123456789'
  Chars = 'abcdefghijklmnopqrstuvwxyz'
  Alphanum = Chars + Chars.upcase + Numbers
  ASCII_readable = '!"#$%&\'()*+,-./[\]^_`{|}~:;<=>?@ ' + Alphanum
  RuChars = UTF2ANSI[Cyrillic::RU_LETTERS[0]]
  RuAlphanum = UTF2ANSI[Cyrillic::RU_LETTERS.join] + Numbers
  
  # Этот метод записывается сюда, а не сразу в String::rand,
  # чтобы удобно было использовать контекст констант
  def self.randstr(len=8, what=:alphanum)
    s = ''
    res = case what
      when :bytes, :binary
        if UrandomEnabled
          SecureRandom.random_bytes len
        else
          len.times {s.concat rand 256}; s
        end
      when :ascii
        if UrandomEnabled
          SecureRandom.random_bytes(len*3).tr("^ -~", '')[0...len]
        else
          len.times {s.concat ASCII_readable[rand 95].ord}; s
        end
      when :char
        if UrandomEnabled
          res = SecureRandom.base64(len*2).tr("^a-z", '')[0...len]
        else
          len.times {s.concat Chars[rand 26].ord}; s
        end
      when :alphanum
        if UrandomEnabled
          res = SecureRandom.base64(len).tr("+/=", '')[0...len]
        else
          len.times {s.concat Alphanum[rand 62].ord}; s
        end
      when :num, :digit
        if UrandomEnabled
          res = SecureRandom.hex(len).tr("^0-9", '')[0...len]
        else
          len.times {s.concat Numbers[rand 10].ord}; s
        end
      when :hex
        if UrandomEnabled
          res = SecureRandom.hex len/2
        else
          len.times {s.concat Numbers[rand 10].ord}; s
        end
      when :cyr, :cyrilic
        if UrandomEnabled
          res = ANSI2UTF[SecureRandom.random_bytes(len*8).tr("^\270\340-\377", '')[0...len]]
        else
          len.times {s.concat RuChars[rand 33].ord}; ANSI2UTF[s]
        end
      when :cyr_full, :cyr_alphanum
        if UrandomEnabled
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
  
end