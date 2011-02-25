# encoding: utf-8
module LibXML

  module XML::XPath
      Finders = {}
      
      def self.filter(xpath)
        return xpath if xpath.ord == ?!
        if x = Finders[xpath]; return x end
        if xpath[%r{\[@?\w+([^\w!]=).+?\]}]
          raise XML::Error, "can't process '#{$1}' operator"
        end
        x = xpath.dup
        x.gsub! %r{\.([\w-]+)([\[\{/]|\Z)}, '[@class="\1"]\2'
        x.gsub! %r{#([\w-]+)([\[\{/]|\Z)}, '[@id="\1"]\2'
        x.gsub! %r{(^|/)([^.#\w*/'"])}, '\1*\2'
        x.gsub! %r{\[([a-z]+)}, '[@\1'
        x.gsub! %r{(\[(?:@\w+!?=)?)['"]?([^'"\]@]+)['"]?\]}, '\1"\2"]'
        if x !~%r{^(#{
                        }(\./|\.//|/|//)?#{
                        }(\w+:)?(\w+|\*)#{                         #  [ns:]name
                        }(\[(@\w+(!?="[^"]+")?|"[^"]+")\])*#{#  attributes [@href!="pics/xynta.jpeg"]
                        }(\[-?\d+\]|\{[^\}]+\})?#{               #  inruby-filters (see finder functions ^)
                        })+$}
          raise XML::Error, "can't process `#{xpath}`" 
        end
        x = '//'+x if x !~ %r{^[./]}
        x.sub! %r{^/}, './'
        Finders[xpath] = x
      end
      
  end
end