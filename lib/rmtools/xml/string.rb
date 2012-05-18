# encoding: utf-8
RMTools::require 'lang/ansi'

class String
  
  def xml_charset
    charset = (charset = self[0,2000].match(/(?:encoding|charset)=(.+?)"/)) ? 
      charset[1].upcase : 'UTF8'
    if charset and charset != 'UTF-8'
      utf!(charset) rescue(charset = nil) 
    end
    charset
  end
  
  def xml_to_utf
    charset = (charset = self[0,2000].match(/(?:encoding|charset)=(.+?)"/)) ? 
      charset[1].upcase : 'UTF8'
    if charset and charset != 'UTF-8'
      utf!(charset) rescue() 
    end
    self
  end
  
  def to_doc(forceutf=nil)
    str = b || "<html/>"
    doc = if forceutf
        XML::HTMLParser.string(str.xml_to_utf, :options => 97,
                                                             :encoding => XML::Encoding::UTF_8).parse
      else
        begin
          if RUBY_VERSION > '1.9'
            XML::HTMLParser.string(str, :options => 97, 
                                                  :encoding => XML::Encoding.const_get(__ENCODING__.to_s.tr('-','_').to_sym)).parse
          else
            XML::HTMLParser.string(str, :options => 97).parse
          end
        rescue
          if enc = xml_charset
            XML::HTMLParser.string(str, :options => 97, 
                           :encoding => XML::Encoding.const_get(enc.upcase.tr('-','_').to_sym)).parse
          else to_doc :force
          end
        end   
      end
    doc.order_elements!
    doc
  end
  
end