# coding: utf-8
RU_LETTERS = "абвгдеёжзийклмнопрстуфхцчшщьыъэюя", "АБВГДЕЁЖЗИЙКЛМНОПРСТУФХЦЧШЩЬЫЪЭЮЯ"
ANSI2UTF = Iconv.new("UTF-8", "WINDOWS-1251").method :iconv
UTF2ANSI = Iconv.new("WINDOWS-1251", "UTF-8").method :iconv

class String
  
  def cyr_ic
    gsub(/[ёЁ]/, '[ёЁ]').gsub(/[йЙ]/, '[йЙ]').gsub(/[цЦ]/, '[цЦ]').gsub(/[уУ]/, '[уУ]').gsub(/[кК]/, '[кК]').gsub(/[еЕ]/, '[еЕ]').gsub(/[нН]/, '[нН]').gsub(/[гГ]/, '[гГ]').gsub(/[шШ]/, '[шШ]').gsub(/[щЩ]/, '[щЩ]').gsub(/[зЗ]/, '[зЗ]').gsub(/[хХ]/, '[хХ]').gsub(/[ъЪ]/, '[ъЪ]').gsub(/[фФ]/, '[фФ]').gsub(/[ыЫ]/, '[ыЫ]').gsub(/[вВ]/, '[вВ]').gsub(/[аА]/, '[аА]').gsub(/[пП]/, '[пП]').gsub(/[рР]/, '[рР]').gsub(/[оО]/, '[оО]').gsub(/[лЛ]/, '[лЛ]').gsub(/[дД]/, '[дД]').gsub(/[жЖ]/, '[жЖ]').gsub(/[эЭ]/, '[эЭ]').gsub(/[яЯ]/, '[яЯ]').gsub(/[чЧ]/, '[чЧ]').gsub(/[сС]/, '[сС]').gsub(/[мМ]/, '[мМ]').gsub(/[иИ]/, '[иИ]').gsub(/[тТ]/, '[тТ]').gsub(/[ьЬ]/, '[ьЬ]').gsub(/[бБ]/, '[бБ]').gsub(/[юЮ]/, '[юЮ]')
  end
  alias :ci :cyr_ic
  
  def utfmask
    gsub(/А/m,"&#1040;").gsub(/Б/m,"&#1041;").gsub(/Е/m,"&#1045;").gsub(/И/m,"&#1048;").gsub(/О/m,"&#1054;").gsub(/У/m,"&#1059;").gsub(/Ы/m,"&#1067;").gsub(/а/m,"&#1072;").gsub(/б/m,"&#1073;").gsub(/е/m,"&#1077;").gsub(/и/m,"&#1080;").gsub(/о/m,"&#1086;").gsub(/у/m,"&#1091;").gsub(/ы/m,"&#1099;")
  end

  def translit
    gsub(/[ёЁ]/, 'yo').gsub(/[йЙ]/, 'y').gsub(/[цЦ]/, 'c').gsub(/[уУ]/, 'u').gsub(/[кК]/, 'k').gsub(/[еЕ]/, 'e').gsub(/[нН]/, 'n').gsub(/[гГ]/, 'g').gsub(/[шШ]/, 'sh').gsub(/[щЩ]/, 'sch').gsub(/[зЗ]/, 'z').gsub(/[хХ]/, 'h').gsub(/[ьЬъЪ]/, "'").gsub(/[фФ]/, 'f').gsub(/[иИыЫ]/, 'i').gsub(/[вВ]/, 'v').gsub(/[аА]/, 'a').gsub(/[пП]/, 'p').gsub(/[рР]/, 'r').gsub(/[оО]/, 'o').gsub(/[лЛ]/, 'l').gsub(/[дД]/, 'd').gsub(/[жЖ]/, 'j').gsub(/[эЭ]/, 'e').gsub(/[яЯ]/, 'ya').gsub(/[чЧ]/, 'ch').gsub(/[сС]/, 's').gsub(/[мМ]/, 'm').gsub(/[тТ]/, 't').gsub(/[бБ]/, 'b').gsub(/[юЮ]/, 'yu')
  end
  
if RUBY_VERSION >= "1.9"
  
  def ru2en
    tr "ёйцукенгшщзхъфывапролдэячсмить/.ю?,б\"№;:жЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИВТЬБЮ", "`qwertyuiop[]asdfghjkl'zxcvbnm|/.&?,@\#$^;~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBDNM<>"
  end
 
  def en2ru
    tr "`qwertyuiop[]asdfghjkl;:'zxcvbnm,./|?\"@\#$^&~QWERTYUIOP{}ASDFGHJKLZXCVBNM<>", "ёйцукенгшщзхъфывапролджЖэячсмитьбю./,Э\"№;:?ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЯЧСМИТЬБЮ"
  end
  
  ANSI_LETTERS_UC = ["\270\340-\377", "\250\300-\337"].force_encodings "Windows-1251"
  ANSI_LETTERS_DC = ANSI_LETTERS_UC.reverse
  ANSI_YOYE = ["\270\250", "\345\305"].force_encodings "Windows-1251"
  ANSI_ENCODING = ANSI_LETTERS_UC[0].encoding
  
  def cupcase
    encoding != ANSI_ENCODING ?
      ANSI2UTF[UTF2ANSI[self].tr(*ANSI_LETTERS_UC)]:
      tr(*ANSI_LETTERS_UC)
  end
  
  def cdowncase
    encoding != ANSI_ENCODING ?
      ANSI2UTF[UTF2ANSI[self].tr(*ANSI_LETTERS_DC)]:
      tr(*ANSI_LETTERS_DC)
  end
  
  def ccap
    self[0].cupcase + self[1..-1]
  end
  
  def cuncap
    self[0].cdowncase + self[1..-1]
  end
  
  def rmumlaut
    encoding != ANSI_ENCODING ?
      ANSI2UTF[UTF2ANSI[self].tr(*ANSI_YOYE)]:
      tr(*ANSI_YOYE)
  end
  
else
  
  def cupcase(encode=1)
    encode ?
      ANSI2UTF[UTF2ANSI[self].tr("\270\340-\377", "\250\300-\337")]:
      tr("\270\340-\377", "\250\300-\337")
  end
  
  def cdowncase(encode=1)
    encode ?
      ANSI2UTF[UTF2ANSI[self].tr("\250\300-\337", "\270\340-\377")]:
      tr("\250\300-\337", "\270\340-\377")
  end
  
  def ccap(encode=1)
    self[0,2].cupcase(encode) + self[2..-1]
  end
  
  def cuncap(encode=1)
    self[0,2].cdowncase(encode) + self[2..-1]
  end
  
  def rmumlaut(encode=1)
    encode ?
      ANSI2UTF[UTF2ANSI[self].tr("\270\250", "\345\305")]:
      tr("\270\250", "\345\305")
  end
  
  def ru2en
    gsub("ё", "`").gsub("й", "q").gsub("ц", "w").gsub("у", "e").gsub("к", "r").gsub("е", "t").gsub("н", "y").gsub("г", "u").gsub("ш", "i").gsub("щ", "o").gsub("з", "p").gsub("х", "[").gsub("ъ", "]").gsub("ф", "a").gsub("ы", "s").gsub("в", "d").gsub("а", "f").gsub("п", "g").gsub("р", "h").gsub("о", "j").gsub("л", "k").gsub("д", "l").gsub("э", "'").gsub("я", "z").gsub("ч", "x").gsub("с", "c").gsub("м", "v").gsub("и", "b").gsub("т", "n").gsub("ь", "m").gsub("/", "|").gsub(".", "/").gsub("ю", ".").gsub("?", "&").gsub(",", "?").gsub("б", ",").gsub("\"", "@").gsub("№", "#").gsub(";", "$").gsub(":", "^").gsub("ж", ";").gsub("Ё", "~").gsub("Й", "Q").gsub("Ц", "W").gsub("У", "E").gsub("К", "R").gsub("Е", "T").gsub("Н", "Y").gsub("Г", "U").gsub("Ш", "I").gsub("Щ", "O").gsub("З", "P").gsub("Х", "{").gsub("Ъ", "}").gsub("Ф", "A").gsub("Ы", "S").gsub("В", "D").gsub("А", "F").gsub("П", "G").gsub("Р", "H").gsub("О", "J").gsub("Л", "K").gsub("Д", "L").gsub("Ж", ":").gsub("Э", "\"").gsub("Я", "Z").gsub("Ч", "X").gsub("С", "C").gsub("М", "V").gsub("И", "B").gsub("Т", "N").gsub("Ь", "M").gsub("Б", "<").gsub("Ю", ">")
  end
  
  def en2ru
    gsub("`", "ё").gsub("q", "й").gsub("w", "ц").gsub("e", "у").gsub("r", "к").gsub("t", "е").gsub("y", "н").gsub("u", "г").gsub("i", "ш").gsub("o", "щ").gsub("p", "з").gsub("[", "х").gsub("]", "ъ").gsub("a", "ф").gsub("s", "ы").gsub("d", "в").gsub("f", "а").gsub("g", "п").gsub("h", "р").gsub("j", "о").gsub("k", "л").gsub("l", "д").gsub(";", "ж").gsub(":", "Ж").gsub("'", "э").gsub("z", "я").gsub("x", "ч").gsub("c", "с").gsub("v", "м").gsub("b", "и").gsub("n", "т").gsub("m", "ь").gsub(",", "б").gsub(".", "ю").gsub("/", ".").gsub("|", "/").gsub("?", ",").gsub("\"", "Э").gsub("@", "\"").gsub("#", "№").gsub("$", ";").gsub("^", ":").gsub("&", "?").gsub("~", "Ё").gsub("Q", "Й").gsub("W", "Ц").gsub("E", "У").gsub("R", "К").gsub("T", "Е").gsub("Y", "Н").gsub("U", "Г").gsub("I", "Ш").gsub("O", "Щ").gsub("P", "З").gsub("{", "Х").gsub("}", "Ъ").gsub("A", "Ф").gsub("S", "Ы").gsub("D", "В").gsub("F", "А").gsub("G", "П").gsub("H", "Р").gsub("J", "О").gsub("K", "Л").gsub("L", "Д").gsub("Z", "Я").gsub("X", "Ч").gsub("C", "С").gsub("V", "М").gsub("B", "И").gsub("N", "Т").gsub("M", "Ь").gsub("<", "Б").gsub(">", "Ю")
  end
  
end
  
  def swap
    sub(/([a-zA-Z])|([а-яА-ЯёЁ])/) {|m| return $~[1]? en2ru: ru2en}
    self
  end
  
  def caps?
    self !~ /[а-яё]/
  end
  
  def cyr?
    self !~ /[^а-яА-ЯёЁ]/
  end
  
  def csqueeze
    ANSI2UTF[UTF2ANSI[self].squeeze]
  end

end

class Regexp
  
  def cyr_ic() Regexp.new(source.cyr_ic, options) end
  alias :ci :cyr_ic
  
end