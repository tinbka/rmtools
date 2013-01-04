# encoding: utf-8
module LibXML

  module XML::XPath
      Finders = {}
      
      def self.filter(xpath)
        xpath = xpath.strip
        return xpath[1..-1] if xpath[0] == ?!
        if x = Finders[xpath]; return x end
        if xpath[%r{\[@?\w+([^\w!]=).+?\]}]
          raise XML::Error, "can't process '#{$1}' operator"
        end
        x = xpath.dup
        x.gsub! %r{([^\\]|\A)\s*>\s*}, '\1/'
        x.gsub! %r{([^\\])\s+}, '\1//'
        x.gsub! %r{(\.([\w-]+))+(?=[\[\{/]|\Z)} do |m| "[@class=\"#{m.split('.')[1..-1]*' '}\"]" end
        x.gsub! %r{#([\w-]+)([\[\{/.]|\Z)}, '[@id="\1"]\2'
        x.gsub! %r{(^|/)([^.#\w*/'"])}, '\1*\2'
        x.gsub! %r{\[([a-z]+)}, '[@\1'
        x.gsub! %r{(\[(?:@\w+!?=)?)['"]?([^'"\]@]+)['"]?\]}, '\1"\2"]'
        if x !~%r{^(#{
                        }(\./|\.//|/|//)?#{
                        }(\w+:)?(\w+|\*)#{                         #  [ns:]name
                        }(\[(@\w+(!?="[^"]+")?|"[^"]+")\])*#{#  attributes [@href!="pics/xynta.jpeg"]
                        }(\[-?\d+\]|\{[^\}]+\})?#{               #  inruby-filters (see finder functions ^)
                        })+$}
          raise XML::Error, "can't process `#{xpath}`; #{x}" 
        end
        x = '//'+x if x !~ %r{^[./]}
        x.sub! %r{^/}, './'
        Finders[xpath] = x
      end
      
  end
end