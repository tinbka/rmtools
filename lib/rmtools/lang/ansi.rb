# encoding: utf-8
if RUBY_VERSION < '2'
  # Although ruby >= 1.9.3 would complain about not using String#encode, iconv is 2-4 times faster and still handles the ruby string encoding
  require 'iconv'
end

module RMTools
  ENCODINGS_PATTERNS = {}
  
  module Cyrillic
    RU_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщьыъэюя", "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
    
    ANSI_LETTERS_UC = ["\270\340-\377", "\250\300-\337"]
    ANSI_LETTERS_DC = ANSI_LETTERS_UC.reverse
    ANSI_YOYE = ["\270\250", "\345\305"]
    if RUBY_VERSION > '1.9'
      ANSI_LETTERS_UC.force_encodings "Windows-1251"
      ANSI_YOYE.force_encodings "Windows-1251"
      ANSI_ENCODING = ANSI_LETTERS_UC[0].encoding
    end
  
    ENCODINGS_PATTERNS["WINDOWS-1251"] = /[#{ANSI_LETTERS_UC.concat(ANSI_YOYE).join}]/
  end

  if RUBY_VERSION < '2'
    ICONVS = {}
    ANSI2UTF = Cyrillic::ANSI2UTF = Iconv.new("UTF-8//IGNORE", "WINDOWS-1251//IGNORE").method(:iconv)
    UTF2ANSI = Cyrillic::UTF2ANSI = Iconv.new("WINDOWS-1251//IGNORE", "UTF-8//IGNORE").method(:iconv)
  else
    ANSI2UTF = Cyrillic::ANSI2UTF = lambda {|str|
      str.encode("WINDOWS-1251", :invalid => :replace, :undef => :replace, :replace => "").encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
    }
    UTF2ANSI = Cyrillic::UTF2ANSI = lambda {|str|
      str.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "").encode("WINDOWS-1251", :invalid => :replace, :undef => :replace, :replace => "")
    }
  end
end
  
class String
  
  if RUBY_VERSION < '2'
    
    def utf(from_encoding='WINDOWS-1251//IGNORE')
      (ICONVS['UTF-8<'+from_encoding] ||= Iconv.new('UTF-8//IGNORE', from_encoding)).iconv(self)
    end
    
    def ansi(from_encoding='UTF-8//IGNORE')
      (ICONVS['WINDOWS-1251<'+from_encoding] ||= Iconv.new('WINDOWS-1251//IGNORE', from_encoding)).iconv(self)
    end
    
    def utf!(from_encoding='WINDOWS-1251//IGNORE')
      replace utf from_encoding
    end
    
    def ansi!(from_encoding='UTF-8//IGNORE')
      replace ansi from_encoding
    end
    
  else
    
    def utf(from_encoding='WINDOWS-1251')
      encode(from_encoding, :invalid => :replace, :undef => :replace, :replace => "").encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
    end
    
    def ansi(from_encoding='UTF-8')
      encode(from_encoding, :invalid => :replace, :undef => :replace, :replace => "").encode("WINDOWS-1251", :invalid => :replace, :undef => :replace, :replace => "")
    end
    
    def utf!(from_encoding='WINDOWS-1251')
      replace utf from_encoding
    end
    
    def ansi!(from_encoding='UTF-8')
      replace ansi from_encoding
    end
    
  end
  
  
  def valid_encoding?
    begin
      self =~ /./
    rescue ArgumentError
      false
    else
      true
    end
  end
  
  def fix_encoding!
    # UTF-8 by default
    return nil if valid_encoding?
    for enc, pattern in ENCODINGS_PATTERNS
      force_encoding(enc)
      if valid_encoding? and self =~ pattern
        return encoding.name.upcase
      end
    end
    false
  end
  
end