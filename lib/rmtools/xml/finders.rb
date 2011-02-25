# encoding: utf-8
RMTools::require 'text/string_scanner'

module LibXML::XML
  DefaultNS = {}

  FindByIndex = lambda {|node, ns, ss|
    node = node.is(Array) ?
      node.sum {|n| n.__find(nil, ns, ss)[ss.matched[1..-2].to_i].to_a} : 
                      node.__find(nil, ns, ss)[ss.matched[1..-2].to_i]
    node.is(Array) && node.size == 1 ? node[0] : node
  }
  FindByProc = lambda {|node, ns, ss|
    node = node.is(Array) ?
      node.sum {|n| n.__find(nil, ns, ss).select(&ss.matched[1..-2]).to_a} : 
                      node.__find(nil, ns, ss).select(&ss.matched[1..-2])
    node.is(Array) && node.size == 1 ? node[0] : node
  }
    
  class Node
    undef :find if method_defined? :find
    undef :at   if method_defined? :at
      
    def __find(xp=nil, ns=nil, ss=nil)
      xp ||= ss.head
      context(ns).find(XPath.filter xp)
    end
      
    def find(xpath, nslist=DefaultNS)
      node = self
      ss = StringScanner.new xpath
      ss.each %r{\[-?\d+\]|\{[^\}]+\}}, 
        ?[ => lambda {|ss| 
          if node; node = FindByIndex[node, nslist, ss]
          else     return []     end  }, 
        ?{ => lambda {|ss| 
          if node; node = FindByProc[node, nslist, ss]
          else     return []     end  },
        nil => lambda {|str|
          node = node.is(Array) ?
            node.sum {|n| n.__find(str, nslist).to_a} : node.__find(str, nslist) 
        }
      node ? (!ss.eos? || node.is(Array)) ? node : [node] :  []
    end
      
    def at(xpath, nslist=DefaultNS)
      find(xpath, nslist)[0]
    end
    
  end
  
  class Document
    undef :find if method_defined? :find
    undef :at   if method_defined? :at
      
    def __find(xp=nil, ns=nil, ss=nil)
      xp ||= ss.head
      context(ns).find(XPath.filter xp)
    end
      
    def find(xpath, nslist=DefaultNS)
      xpath.sub!(/^([\w*])/, '//\1')
      node = self
      ss = StringScanner.new xpath
      ss.each %r{\[-?\d+\]|\{[^\}]+\}}, 
        ?[ => lambda {|ss|
          if node; node = FindByIndex[node, nslist, ss]
          else     return []     end  }, 
        ?{ => lambda {|ss|
          if node; node = FindByProc[node, nslist, ss]
          else     return []     end  },
        nil => lambda {|str|
          node = node.is(Array) ?
            node.sum {|n| n.__find(str, nslist).to_a} : node.__find(str, nslist) 
        }
      node ? (!ss.eos? || node.is(Array)) ? node : [node] :  []
    end
      
    def at(xpath, nslist=DefaultNS)
      find(xpath, nslist)[0]
    end
    
  end
    
end