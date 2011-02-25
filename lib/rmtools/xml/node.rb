# encoding: utf-8
module LibXML::XML
    
    class Node
      __init__
    
      alias :get :[]
      alias :root? :parent?
      alias :root :parent
      
      def [](*item)
        if item[0].is String
          get item[0]
        else to_a[*item]
        end
      end
      
    # JQUERY-LIKE MANIPULATION
      def self.build(str, copy=true)
        nodes = Document.string("<html>#{str}</html>", :options=>97).root.to_a
        copy ? nodes.copies(true) : nodes
      end
      
      def self.from(str, copy=true) 
        build(str, copy)[0] 
      end
      
      def append(obj)
        case obj
          when Node then self << obj
          when Array then obj.each {|n| append n}
          else append Node.build obj.to_s
        end
        self
      end
      
      def after(obj)
        case obj
          when Node then self.next = obj
          when Array then obj.reverse_each {|n| after n}
          else after Node.build obj.to_s
        end
        self
      end
      
      def before(obj)
        case obj
          when Node then self.prev = obj
          when Array then obj.each {|n| before n}
          else before Node.build obj.to_s
        end
        self
      end
      
      def prepend obj
        first ? first.before(obj) : append(obj)
      end
      
      def html(str=nil)
        if str
          self.content = ''
          append str
        else to_a.join
        end
      end
      
      def text(str=nil)
        if str
          self.content = str
          self
        else
          self.content
        end
      end
      
      
    # FETCH CONTENT
      def text_nodes(lvl=0) # 0 => nevermind
        nodes = []
        xp = "*"
        loop {
          ary = find(xp).to_a
          break if ary.empty?
          nodes.concat(ary.childrens.flatten.find_all {|e| 
            e.text? && e.text[/[a-zA-Zа-яА-Я]/]
          })
          xp << "/*"
          break if (lvl -= 1) == 0
        }
        nodes
      end
      
      
    # FORM
      InputsMapper = lambda {|i| [i['name'], i.name == 'select' ?
        (i.at('option[selected]') || i.at('option')) : 
        (i.value || i.checked)]
      }
      def inputs
        [Hash[find("input[name][type=hidden]").map(&InputsMapper)],
         Hash[
            ["input[name][type!=hidden]", "textarea[name]", "select[name]"].sum {|s|
              find(s).map &InputsMapper
            }
        ]]
      end
      
      def inputs_all
        Hash[["input[name]", "textarea[name]", "select[name]"].sum {|s|
                  find(s).map &InputsMapper
        }]
      end
      
      
    # ATTRIBUTES
      def to_hash
        attributes.to_hash
      end
      
      %w{style id width height onclick ondbclick onmousedown onmousemove onmouseout onmouseover onmouseup src onerror onload href type value size onchange onselect onblur onfocus onfocusin onfocusout onkeydown onkeypress onkeyup action target enctype onsubmit checked selected}.each {|name|
        define_method(name) {self[name]}
        define_method(name+'=') {|value| self[name] = value}
      }
      def klass() self['class'] end
      def klass=(name) self['class'] = name end
      def metod() self['method'] end
      def metod=(name) self['method'] = name end
      
      
    # RELATED FINDERS
      alias :prevNode :prev
      alias :nextNode :next
      
      def prev(*args) getNode :prevNode, *args end
      def next(*args) getNode :nextNode, *args end
      def closest(*args) getNode :parent, *args end
      
    private
      Searches = {}
      def getNode meth, filter=nil, skip=true
        unless filter
          send meth
        else
          return unless el = skip ? send(meth) : self
          unless nil;cond = Searches[filter]
            m = filter.match %r{(\w+)?#{         #   span
                   }(?:\.(\w+))?(?:#([\-\w]+))?#{#   .class #id
                   }(\[((\w+)#{                         # [name
                   }(([!^$~]?)=([\-\w]+))?)?\])#{#           ^= name-beg]
                   }?}
            cond = []
            cond << "_.name == '#{m[1]}'" if m[1]
            cond << "_['class'] == '#{m[2]}'" if m[2]
            cond << "_['id'] == '#{m[3]}'" if m[3]
            if m[4]
              if m[5]
                attr = m[6]
                attr_cond = m[7]
                if attr_cond
                  cond_op = m[8]
                  attr_value = m[9]
                  cond << case cond_op
                      when '!'; "_['#{attr}'] !=  '#{attr_value}' "
                      when '^'; "_['#{attr}'] =~ /^#{attr_value}/ "
                      when '$'; "_['#{attr}'] =~  /#{attr_value}$/"
                      when '~'; "_['#{attr}'] =~  /#{attr_value}/ "
                      else   "_['#{attr}'] == '#{attr_value}'"
                    end
                else
                  cond << "_['#{attr}']"
                end
              elsif !(m[2] or m[3])
                cond << "!_.attributes?"
              end
            end
            cond = Searches[filter] = Proc.eval("|_| #{cond*' && '}")
          end
          if cond[el]
            el
          else
            while el = el.send(meth) and el.kinda Node and !cond[el]; end
            el if el and el.kinda Node and cond[el]
          end
        end
      end
      
    end
   
    class Attributes
      
      def to_hash
        Hash[map {|a| [a.name,a.value]}]
      end
      
    end
    
end