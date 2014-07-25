module RMTools
  module String
    module Russian
      module Transform
        
        def cupcase
          encoding != ANSI_ENCODING ?
            ANSI2UTF[UTF2ANSI[self].tr(*ANSI_LETTERS_UC)] : 
            tr(*ANSI_LETTERS_UC)      
        end
        def cupcase!
          encoding != ANSI_ENCODING ?
            ANSI2UTF[UTF2ANSI[self].tr!(*ANSI_LETTERS_UC)] : 
            tr!(*ANSI_LETTERS_UC)      
        end
        
        def cdowncase
          encoding != ANSI_ENCODING ?
            ANSI2UTF[UTF2ANSI[self].tr(*ANSI_LETTERS_DC)] : 
            tr(*ANSI_LETTERS_DC)
        end
        def cdowncase!
          encoding != ANSI_ENCODING ?
            ANSI2UTF[UTF2ANSI[self].tr!(*ANSI_LETTERS_DC)] : 
            tr!(*ANSI_LETTERS_DC)
        end
        
        def rmumlaut
          encoding != ANSI_ENCODING ?
            ANSI2UTF[UTF2ANSI[self].tr(*ANSI_YOYE)] :
            tr(*ANSI_YOYE)
        end
          
        # full upcase, because cdowncase doesn't convert non-cyrillic
        def fupcase
          upcase.cupcase
        end
        def fupcase!
          res = upcase!
          cupcase! or res
        end
        
        # full downcase, because cdowncase doesn't convert non-cyrillic
        def fdowncase
          downcase.cdowncase
        end
        def fdowncase!
          res = downcase!
          cdowncase! or res
        end
        
        def ccap
          self[0].cupcase + self[1..-1]
        end
        
        def cuncap
          self[0].cdowncase + self[1..-1]
        end
        

        def translit
          gsub(/ё/i, 'yo').gsub(/й/i, 'y').gsub(/ц/i, 'c').gsub(/у/i, 'u').gsub(/к/i, 'k').gsub(/е/i, 'e').gsub(/н/i, 'n').gsub(/г/i, 'g').gsub(/ш/i, 'sh').gsub(/щ/i, 'sch').gsub(/з/i, 'z').gsub(/х/i, 'h').gsub(/[ьъ]/i, "'").gsub(/ф/i, 'f').gsub(/[иы]/i, 'i').gsub(/в/i, 'v').gsub(/а/i, 'a').gsub(/п/i, 'p').gsub(/р/i, 'r').gsub(/о/i, 'o').gsub(/л/i, 'l').gsub(/д/i, 'd').gsub(/ж/i, 'j').gsub(/э/i, 'e').gsub(/я/i, 'ya').gsub(/ч/i, 'ch').gsub(/с/i, 's').gsub(/м/i, 'm').gsub(/т/i, 't').gsub(/б/i, 'b').gsub(/ю/i, 'yu')
        end
        
        def ru2en
          tr "ёйцукенгшщзхъфывапролдэячсмить/.ю?,б\"№;:жЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЖЭЯЧСМИВТЬБЮ", "`qwertyuiop[]asdfghjkl'zxcvbnm|/.&?,@\#$^;~QWERTYUIOP{}ASDFGHJKL:\"ZXCVBDNM<>"
        end
       
        def en2ru
          tr "`qwertyuiop[]asdfghjkl;:'zxcvbnm,./|?\"@\#$^&~QWERTYUIOP{}ASDFGHJKLZXCVBNM<>", "ёйцукенгшщзхъфывапролджЖэячсмитьбю./,Э\"№;:?ЁЙЦУКЕНГШЩЗХЪФЫВАПРОЛДЯЧСМИТЬБЮ"
        end
    
        def swap
          sub(/([a-zA-Z])|([А-пр-ёЁ])/) {|m| return $~[1] ? en2ru : ru2en}
          self
        end
        
      end
    end
  end
end