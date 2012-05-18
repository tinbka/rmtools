# encoding: utf-8
require 'iconv'
# Although ruby >= 1.9.3 would complain about not using String#encode, iconv is 2-4 times faster and still handles the ruby string encoding

module RMTools
  ANSI2UTF = Iconv.new("UTF-8", "WINDOWS-1251").method :iconv
  UTF2ANSI = Iconv.new("WINDOWS-1251", "UTF-8").method :iconv

  module Cyrillic
    RU_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщьыъэюя", "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
    
    if RUBY_VERSION > '1.9'
      ANSI_LETTERS_UC = ["\270\340-\377", "\250\300-\337"].force_encodings "Windows-1251"
      ANSI_LETTERS_DC = ANSI_LETTERS_UC.reverse
      ANSI_YOYE = ["\270\250", "\345\305"].force_encodings "Windows-1251"
      ANSI_ENCODING = ANSI_LETTERS_UC[0].encoding
    end
  end
  
end
  
class String
  
  # Actually, for short strings and 1251<->65001 it's much faster to use predefined ANSI2UTF and UTF2ANSI procs
  def utf(from_encoding='WINDOWS-1251')
    Iconv.new('UTF-8', from_encoding).iconv(self)
  end
  
  def ansi(from_encoding='UTF-8')
    Iconv.new('WINDOWS-1251', from_encoding).iconv(self)
  end
  
  def utf!(from_encoding='WINDOWS-1251')
    replace utf from_encoding
  end
  
  def ansi!(from_encoding='UTF-8')
    replace ansi from_encoding
  end
  
end