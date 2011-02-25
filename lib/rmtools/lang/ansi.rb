# encoding: utf-8
require 'iconv'

module RMTools
  ANSI2UTF = Iconv.new("UTF-8", "WINDOWS-1251").method :iconv
  UTF2ANSI = Iconv.new("WINDOWS-1251", "UTF-8").method :iconv
  
  module Cyrillic
    RU_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщьыъэюя", "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
    
    if RUBY_VERSION >= '1.9'
      ANSI_LETTERS_UC = ["\270\340-\377", "\250\300-\337"].force_encodings "Windows-1251"
      ANSI_LETTERS_DC = ANSI_LETTERS_UC.reverse
      ANSI_YOYE = ["\270\250", "\345\305"].force_encodings "Windows-1251"
      ANSI_ENCODING = ANSI_LETTERS_UC[0].encoding
    end
  end
end