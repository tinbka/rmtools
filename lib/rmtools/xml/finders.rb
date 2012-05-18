# encoding: utf-8
RMTools::require 'text/string_scanner'

module LibXML::XML
  DefaultNS = {}

  FindByIndex = lambda {|node, ns, ss|
    index = ss.matched[1..-2]
    if index.index('.')
      range = Range(*index.split('..').to_is)
      node = node.is(Array) ?
        node.sum([]) {|n| n.__find(nil, ns, ss).to_a[range]} : 
                        node.__find(nil, ns, ss).to_a[range]
    else
      node = node.is(Array) ?
        node.map {|n| n.__find(nil, ns, ss)[index.to_i]}.compact : 
                        node.__find(nil, ns, ss)[index.to_i]
    end
    node.is(Array) && node.size < 2 ? node[0] : node
  }
  
  FindByProc = lambda {|node, ns, ss|
    str_to_eval = ss.matched[1..-2]
    block = eval "lambda {|_| #{'_' if !str_to_eval['_']}#{str_to_eval}}"
    node = node.is(Array) ?
      node.sum([]) {|n| n.__find(nil, ns, ss).select(&block).to_a} : 
                      node.__find(nil, ns, ss).select(&block)
    node.is(Array) && node.size < 2 ? node[0] : node
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
      ss.each %r{\[-?\d+(\.\.\d+)?\]|\{[^\}]+\}}, 
        ?[ => lambda {|ss| 
          if node; node = FindByIndex[node, nslist, ss]
          else     return []     end  }, 
        ?{ => lambda {|ss| 
          if node; node = FindByProc[node, nslist, ss]
          else     return []     end  },
        nil => lambda {|str|
          node = node.is(Array) ?
            node.sum([]) {|n| n.__find(str, nslist).to_a} : node.__find(str, nslist) 
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
      ss.each %r{\[-?\d+(\.\.\d+)?\]|\{[^\}]+\}}, 
        ?[ => lambda {|ss|
          if node; node = FindByIndex[node, nslist, ss]
          else     return []     end  }, 
        ?{ => lambda {|ss|
          if node; node = FindByProc[node, nslist, ss]
          else     return []     end  },
        nil => lambda {|str|
          node = node.is(Array) ?
            node.sum([]) {|n| n.__find(str, nslist).to_a} : node.__find(str, nslist) 
        }
      node ? (!ss.eos? || node.is(Array)) ? node : [node] :  []
    end
      
    def at(xpath, nslist=DefaultNS)
      find(xpath, nslist)[0]
    end
    
  end
    
end