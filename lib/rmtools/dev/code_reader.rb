RMTools::require 'text/string_scanner'

module RMTools
  class CodeReader
    
    module RE
      leftop = '\[{(<=>~+\-*,;?:^&\|'
      rightop = '\])}?!'
      sname = '\w<=>~+\-*/\]\[\^%!?@&\|'
      compname = "([\\.:#{sname}]+)"
      name = "([#{sname}]+)"
      mname = '([:\w]+)'
      call_ = '(\{s*\||([\w?!)]|\.((\[\]|[<=>])?=[=~]?|[<>*\-+/%^&\|]+))[ \t]*\{)'
      space = '[ \t]+'
      space_ = '[ \t]*'
      kw = 'if|elsif|else|unless|while|until|case|begin|rescue|when|then|or|and|not'
      heredoc_handle = %q{<<(-)?(\w+|`[^`]+`|'[^']+'|"[^"]+")}
      heredoc = %{([\\s#{leftop}]|[#{leftop}\\w!][ \t])\\s*#{heredoc_handle}}
      re_sugar = %{(^|[#{leftop}\\n;]|\W!|\\b(#{kw})[ \t]|[\\w#{rightop}]/)\\s*/}
      percent = '%([xwqrQW])?([\\/<({\[!\|])'
      simple = [re_sugar, percent, '[#\'"`]']*'|'
      mod_def = "module#{space+mname}"
      class_def = "class(?:#{space_}(<<)#{space_}|#{space})([$@:\\w]+)(?:#{space_}<#{space_+mname})?"
      method_def = "def#{space+compname}"
      alias_def = "alias#{space}:?#{name+space}:?#{name}"
      
      StringParseRE = /#{heredoc}|#{simple}|[{}]|[^\w#{rightop}'"`\/\\]\?\\?\S/m
      HeredocParseRE = /\n|#{heredoc}|#{simple}/
      StringRE = /(^['"`]$)|^#{percent}$/
      RERE = %r{(?:^|[#{leftop}\\w!\\s/])\\s*(/)}
      HeredocRE = heredoc_handle.to_re
      Symbol = /^:#{name}$/
      Attrs = /\s(c)?(?:attr_(reader|writer|accessor))#{space}((?::\w+#{space_},\s*)*:\w+)/
      Include = /\s(include|extend)#{space+mname}/
      AliasMethod = /\salias_method :#{name+space_},#{space_}:#{name}/
      Beginners = /(([#{leftop}\n]?#{space_})(if|unless|while|until))#{
        }|(.)?(?:(do|for)|begin|case)/
      EOF = /($0\s*==\s*__FILE__\s*|__FILE__\s*==\s*\$0\s*)?\n/
      BlockStart = /(?:^\{\s*\||.\{)$/
      Ord = /^.\?\\?\S$/
      
      MainParseRE = /#{simple
        }|#{call_}|[{}]#{
        }|(^|\n)=begin\b#{
        }|^#{space_}[;\(]?#{space_}(#{mod_def}|#{method_def})#{
        }|:#{name}#{
        }|[^\w#{rightop}'"`\/\\]\?\\?\S#{
        }|#{heredoc
        }|(^|[#{leftop}\n])#{space_}((if|unless)\b|#{
                                                    }[;\(]?#{space_+class_def})#{
        }|(^|[\n;])#{space_}(while|until)\b#{
        }|(^|[#{leftop}\s])(do|case|begin|for)\b#{
        }|\sc?(attr_(reader|writer|accessor))#{space}(:\w+#{space_},\s*)*:\w+?[\n;]#{
        }|\salias_method :#{name+space_},#{space_}:#{name
        }|\s(include|extend)#{space+mname
        }|(^|[;\s])(#{alias_def}|end|__END__)\b/m
        
      ModDef = mod_def.to_re
      ClassDef = class_def.to_re
      MethodDef = method_def.to_re
      AliasDef = alias_def.to_re
      
      Closers = {'<' => '>', '{' => '}', '[' => ']', '(' => ')'}
    end
    
    
    def initialize
      @MethodCache = {'Object' => {}}
      @ReadPaths = {}
    end
    
    def string(s, m)
      return if m[1] and s.- == '$'
      opener = m[1] || m[3] || m[5]
      if opener == m[5]
        closer = opener = m[5].tr('`\'"', '')
        quote_re = /\\|\n#{'\s*' if m[4]}#{closer}/
      else
        closer = RE::Closers[opener] || opener
        quote_re = /\\|#{Regexp.escape closer}/
      end
      openers_cnt = 1
      curls_cnt = 0
      backslash = false
      quote_re |= /#\{/ if (m[5] and m[5].ord != ?') or closer =~ /[\/"`]/ or (m[2] =~ /[xrQW]/ or m[3])
      instructions = [
        [RE::Ord],
        [/\s*#{Regexp.escape closer}$/, lambda {|s, m|
          if backslash
            backslash = false
            break if s.- == '\\' and m[0] == closer
          end
          if (openers_cnt -= 1) == 0
            throw :EOS 
          end
        }],
        [/\\/, lambda {|s, m|
          prev = s.-
          backslash = true
          if prev == '\\'
            i = 2
            while prev == '\\'
              prev = s.prev_in i
              i += 1
              backslash = !backslash
            end
          end
        }],
        [/\#\{/, lambda {|s, m| 
          if backslash
            backslash = false
            break if s.- == '\\'
          end
          curls_cnt += 1
          catch(:inner_out) {s.each(RE::StringParseRE, [
              [/^\#$/, lambda {|s, m| s.scan_until(/\n/)}],
              [/^\{$/, lambda {|s, m| curls_cnt += 1}],
              [/^\}$/, lambda {|s, m| throw :inner_out if (curls_cnt -= 1) == 0}],
              [RE::HeredocRE, method(:heredoc)],
              [RE::StringRE, method(:string)],
              [RE::RERE, method(:string)]
          ])}
        }]
      ]
      if closer != opener
        quote_re |= /#{Regexp.escape opener}/
        instructions << [/#{Regexp.escape opener}$/, lambda {|s, m|
          if backslash
            backslash = false
            break if s.- == '\\'
          end
          openers_cnt += 1
        }]
      end
        
      catch(:EOS) {s.each(quote_re, instructions)}
    end
    
    def heredoc(s, m)
      heredoc_list = [m[1..2]]
      catch(:EOL) {s.each(RE::HeredocParseRE, [
          [/[#\n]/, lambda {|s, m| 
            s.scan_until(/\n/) if m[0] == '#'
            heredoc_list.each {|opener| string(s, [nil]*4+opener)}
            throw :EOL
          }],
          [RE::HeredocRE, lambda {|s, m| heredoc_list << m[1..2]}],
          [RE::StringRE, method(:string)],
          [RE::RERE, method(:string)]
      ])}
    end

    def parse_file(path)
      @stack = []
      
      if path.inline
        return if @ReadPaths[path]
        lines = get_lines(path)[0]
        @ReadPaths[path] = true
      else
        lines = path.sharp_split(/\n/)
      end
      ss = StringScanner lines.join
      
      curls_cnt = 0
      catch(:EOF) {ss.each(RE::MainParseRE, [
          [/^\#/, lambda {|s, m| s.scan_until(/\n/)}],
          
          [RE::StringRE, method(:string)],
          
          [/^\{$/, lambda {|s, m| curls_cnt += 1}],
          
          [/^\}$/, lambda {|s, m| 
            if curls_cnt == 0
              @stack.pop
            else
              curls_cnt -= 1
            end
          }],
          
          [RE::Ord],
          
          [RE::BlockStart, lambda {|s, m| @stack << [:block]}],
          
          [RE::ModDef, lambda {|s, m|
            @stack << [:mod, m[1]]
            @MethodCache[clean_stack.lasts*'::'] = {}
          }],
          
          [RE::ClassDef, lambda {|s, m|
            _stack = clean_stack
            if _stack[-1] == [:block]
              @stack << [:beginner]
              break
            elsif m[1]
              if m[2] =~ /^[@$]/
                @stack << [:beginner]
              elsif _stack.any? and _stack[-1][0] == :def
                @stack << [:beginner]
              else
                slf = _stack.lasts*'::'
                name = m[2].sub 'self.', ''
                name.sub! 'self', slf
                name = fix_module_name slf, name
                @stack << [:singleton, name]
              end
            else
              new = clean_stack.lasts*'::'
              @stack << [:class, m[2]]
              name = fix_module_name new, m[3] if m[3]
              new << '::' if new.b
              new << m[2]
              @MethodCache[new] ||= {}
              inherit! new, name if m[3]
            end
          }],
          
          [RE::MethodDef, lambda {|s, m|
            _stack = clean_stack(true)
            if _stack[-1] == [:block]
              @stack << [:beginner]
              break
            end
            start = s.pos - s.matched[/[^\n]+$/].size
            name = m[1].sub(/::([^:.]+)$/, '.\1')
            name.sub!(/#{_stack.last[1]}\./, 'self.') if _stack.any?
            if name[/^self\.(.+)/]
              @stack << [:def, "#{_stack.lasts*'::'}.#$1", start]
            elsif name['.'] and name =~ /^[A-Z]/
              mod, name = name/'.'
              fix_module_name(_stack.lasts*'::', mod) >> '.' >> name
              @stack << [:def, name, start]
            else
              prefix = (_stack.any? && _stack[-1][0] == :singleton) ? _stack[-1][1]+'.' : _stack.lasts*'::'+'#'
              @stack << [:def, prefix+name, start]
            end
          }],
          
          [RE::AliasDef, lambda {|s, m|
            _stack = clean_stack
            case _stack.any? && _stack[-1][0]
              when false, :def, :block
                break
              when :singleton
                prefix = _stack[-1][1]
                new, old = '.'+m[1], '.'+m[2]
              else
                prefix = _stack.lasts*'::'
                new, old = '#'+m[1], '#'+m[2]
            end
            @MethodCache[prefix][new] = @MethodCache[prefix][old] || "def #{new}(*args)\n  #{old}(*args)\nend"
          }],
          
          [RE::Symbol],
          
          [RE::RERE, method(:string)],
          
          [RE::HeredocRE, method(:heredoc)],
          
          [/(^|\n)=begin/, lambda {|s, m| s.scan_until(/\n=end\s*\n/)}],
          
          [RE::Attrs, lambda {|s, m|
            _stack = clean_stack
            if _stack[-1][0] == :class
              prefix = _stack.lasts*'::'
              attrs = (m[3]/',').map {|attr| (m[1] ? '.' : '#')+attr.strip[1..-1]}
              if m[2].in %w(reader accessor)
                  attrs.each {|attr| (@MethodCache[prefix][attr] ||= []) << "def #{'self.' if m[1]}#{attr}\n  #{'@' if m[1]}@#{attr}\nend"}
              end
              if m[2].in %w(writer accessor)
                  attrs.each {|attr| (@MethodCache[prefix][attr] ||= []) << "def #{'self.' if m[1]}#{attr}=value\n  #{'@' if m[1]}@#{attr} = value\nend"}
              end
            end
          }],
          
          [RE::Include, lambda {|s, m|
            _stack = clean_stack
            if _stack.empty?
              if m[1] == 'include'
                inherit! 'Object', m[2] 
              else
                inherit_singletons! 'Object', m[2] 
              end
            elsif !_stack[-1][0].in([:def, :block]) and m[2] =~ /^[A-Z]/
              if m[1] == 'include'
                inherit! _stack.lasts*'::', m[2] 
              else
                inherit_singletons! _stack.lasts*'::', m[2] 
              end
            end
          }],
          
          [RE::AliasMethod, lambda {|s, m|
            _stack = clean_stack
            if _stack[-1][0] == :class
              new, old = m[1..2]
              prefix = _stack.lasts*'::'
              @MethodCache[prefix][new] = @MethodCache[prefix][old] || "def #{new}(*args)\n  #{old}(*args)\nend"
            end
          }],
          
          [RE::Beginners, lambda {|s, m|
            if (m[2] and s.last != 0 and m[2].tr(' \t', '').empty? and !(s.string[s.last-1,1].to_s)[/[\n;]/])
            else
              if m[3] == 'if' and @stack.empty? and s.check_until(RE::EOF) and s.matched != "\n"
                throw :EOF
              end
              @stack << [m[5] ? :block : :beginner]
            end
          }],
          
          [/(^|[\s;])end/, lambda {|s, m|
            exit = @stack.pop
            case exit[0]
              when :def
                prefix, name = exit[1].sharp_split(/[.@#]/, 2)
                if !name
                  prefix, name = 'Object', prefix
                end
                if @MethodCache[prefix]
                  (@MethodCache[prefix][name] ||= []) << (path.inline ? [path, exit[2]...s.pos] : s.string[exit[2]...s.pos])
                end
            end
          }],
          
          [/(^|[\s;])__END__/, lambda {|s, m| throw :EOF}]
      ])}
      ss
    end

    def clean_stack(no_def=false)
      @stack.select {|e| e[0] != :beginner and !no_def || e[0] != :def}
    end

    def inherit!(descendant, ancestor)
      @MethodCache[descendant].reverse_merge((
        @MethodCache[fix_module_name(descendant, ancestor)] ||= {}
      ).map_values {|defs| defs.dup})
    end

    def inherit_singletons!(descendant, ancestor)
      (@MethodCache[fix_module_name(descendant, ancestor)] ||= {}).each {|name, defs|
        @MethodCache[descendant][name.sub('#', '.')] = defs.dup if name.ord == ?#
      }
    end

    def fix_module_name(current, name)
      if name =~ /^::/ or current == ''
        current+name
      elsif name == current or name == 'self'
        current
      elsif name !~ /^[A-Z]/
        current+'#'+name
      else 
        path = current+'::'+name
        if @MethodCache[path]
          path
        else 
          @MethodCache[name] ||= {}
          name
        end
      end
    end

    def get_lines(path)
      SCRIPT_LINES__.select {|d, f| d[path]}.lasts
    end
    
    def print_lines(prefix, name, all)
      map = lambda {|lines|
          if lines.is Array
            lines = SCRIPT_LINES__[lines[0]].join[lines[1]]
          end
          lines           }
      methods = all ? @MethodCache[prefix][name].map(&map) : map.call(@MethodCache[prefix][name].last)
      puts methods
    end

    def code_of(path, name=nil, all=false)
      if name.in [true, :all]
        all = true
      end
      if path.is String
        prefix, name = path.sharp_split(/[.#]/, 2)
      elsif Class === path
        prefix = path.name
        name = ".#{name}"
      else
        prefix = path.class.name
        name = "##{name}"
      end
      if !(@MethodCache[prefix]||{})[name]
        puts "looking up script lines, please wait..."
        SCRIPT_LINES__.each_key {|k| parse_file k
                                                    break if (@MethodCache[prefix]||{})[name]
        }
      end
      if !(@MethodCache[prefix]||{})[name]
        print "nothing was found for #{prefix}#{name}"
        name = name.tr('#.', '.#')
        if (@MethodCache[prefix]||{})[name]
          puts ", but found for #{name}:"
          print_lines prefix, name, all
        else
          return puts ''
        end
      end
      puts "code for #{prefix}#{name}:"
      print_lines prefix, name, all
    end

  end  
  
  Reader = CodeReader.new
end

module Kernel
  
  def code_of(*args)
    RMTools::Reader.code_of(*args)
  end

end

class Method
  
  def code(all=false)
    RMTools::Reader.code_of(receiver, name, all)
  end
  
end