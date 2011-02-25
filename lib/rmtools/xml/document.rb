# encoding: utf-8
module LibXML::XML

  class Document
      
    def title
      (a = context(nil).find('head//title')[0]) && a.content.strip
    end
    
    def body
      context(nil).find('body')[0] || root
    end
      
    def to_xhtml
      html = to_s
      html.sub! "<?xml version=\"1.0\" encoding=\"UTF-8\" standalone=\"yes\"?>\n", ''
      html.gsub! %r{<a name(=\"\S+\")\s+id\1(\s*[a-z0-9="]*\s*>)}, '<a name\1\2'
      html.gsub! %r{\n?<!\[CDATA\[\s*(.+?)\s*\]\]>\n?}m, '\1'
      html.gsub! %r{<html( +xmlns=\"http://\S+\")\1}, '<html\1'
      html
    end
    
    def inspect
      "<#XMLDocument #{title && "«#{title}» "}(#{to_xhtml.size.bytes})>"
    end
      
  end
    
end