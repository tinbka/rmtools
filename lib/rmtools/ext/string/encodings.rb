module RMTools
  module String
    module Encodings
    
      def utf(from_encoding="UTF-16")
        encode(from_encoding, :invalid => :replace, :undef => :replace, :replace => "").encode("UTF-8", :invalid => :replace, :undef => :replace, :replace => "")
      end
      
      def ansi(from_encoding="UTF-16")
        encode(from_encoding, :invalid => :replace, :undef => :replace, :replace => "").encode("WINDOWS-1251", :invalid => :replace, :undef => :replace, :replace => "")
      end
      
      def utf!(from_encoding="UTF-16")
        replace utf from_encoding
      end
      
      def ansi!(from_encoding="UTF-16")
        replace ansi from_encoding
      end
    
      def is_utf!(utf='UTF-8')
        force_encoding utf
      end
  
      def utf?
        begin
          encoding == Encoding::UTF_8 and self =~ /./u
        rescue Encoding::CompatibilityError
          false
        end
      end
      
      def find_compatible_encoding
        # UTF-8 by default
        return nil if utf?
        for enc, pattern in ENCODINGS_PATTERNS
          force_encoding(enc)
          if self =~ pattern
            return enc
          end
        end
        false
      end
      
    end
  end
end