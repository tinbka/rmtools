# encoding: utf-8
RMTools::require 'lang/ansi'

class String
    # Actually, for short strings and 1251<->65001 it's much faster to use predefined ANSI2UTF and UTF2ANSI procs
    def utf(from_encoding='WINDOWS-1251')
      Iconv.new('UTF-8', from_encoding).iconv(self)
    end
    
    def utf!(from_encoding='WINDOWS-1251')
      replace utf from_encoding
    end
    
    def ansi(from_encoding='UTF-8')
      Iconv.new('WINDOWS-1251', from_encoding).iconv(self)
    end
    
    def ansi!(from_encoding='UTF-8')
      replace ansi from_encoding
    end
end