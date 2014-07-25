module RMTools
  ENCODINGS_PATTERNS = {}
  
  module Russian
    RU_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщьыъэюя", "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
    
    ANSI_LETTERS_UC = ["\270\340-\377", "\250\300-\337"]
    ANSI_LETTERS_DC = ANSI_LETTERS_UC.reverse
    ANSI_YOYE = ["\270\250", "\345\305"]
    
    ANSI_LETTERS_UC.force_encodings "Windows-1251"
    ANSI_YOYE.force_encodings "Windows-1251"
    ANSI_ENCODING = ANSI_LETTERS_UC[0].encoding
  
    ENCODINGS_PATTERNS["WINDOWS-1251"] = /[#{ANSI_LETTERS_UC.join}]/
  end

  ANSI2UTF = Cyrillic::ANSI2UTF = lambda {|str|
    str.encode("WINDOWS-1251", :invalid => :replace, :undef => :replace, :replace => "").encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
  }
  UTF2ANSI = Cyrillic::UTF2ANSI = lambda {|str|
    str.encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "").encode("WINDOWS-1251", :invalid => :replace, :undef => :replace, :replace => "")
  }
end