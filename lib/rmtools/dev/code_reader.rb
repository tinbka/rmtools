# encoding: utf-8
RMTools::require 'text/string_scanner'

module RMTools
  class CodeReader
    attr_reader :MethodCache, :stack
    
    module Defaults
      Leftop = leftop = '\[{(<=>~+\-*,;^&\|'
      rightop = '\])}?!'
      sname = '\w<=>~+\-*/\]\[\^%!?@&\|'
      compname = "([\\.:#{sname}]+)"
      name = "([#{sname}]+)"
      mname = '([:\w]+)'
      call_ = '(\{s*\||([\w][?!]?|\)|\.((\[\]|[<=>])?=[=~]?|[<>*\-+/%^&\|]+))[ \t]*\{)'
      space = '[ \t]+'
      space_ = '[ \t]*'
      kw = 'if|elsif|else|unless|while|until|case|begin|rescue|when|then|or|and|not'
      heredoc_handle = %q{<<(-)?(\w+|`[^`]+`|'[^']+'|"[^"]+")}
      heredoc = %{([\\s#{leftop}?]|[#{leftop}:\\w!?][ \t])\\s*#{heredoc_handle}}
      re_sugar = %{(^|[#{leftop}\\n?;]|\W!|(^|[\{(,;\\s])(#{kw})[ \t]|[\\w#{rightop}]/)\\s*/}
      percent = '%([xwqrQW])?([\\/<({\[!\|])'
      simple = [re_sugar, percent, '[#\'"`]']*'|'
      mod_def = "module +#{mname}"
      class_def = "class(?: *(<<) *| +)([$@:\\w]+)(?: *< *#{mname})?"
      method_def = "def +#{compname}"
      alias_def = "alias +:?#{name} +:?#{name}"
      Ender = '\s*\)? *(?:end\b|[\n;})\]])'
      
      StringParseRE = /#{heredoc}|#{simple}|[{}]|[^\w#{rightop}'"`\/\\]\?\\?\S/m
      HeredocParseRE = /\n|#{heredoc}|#{simple}/m
      ArgumentsParseRE = /#{simple
        }|(\d[\d.]+|:[@$_a-z]\w*|[@$]\w+) *#{
        }|([@$_a-z][:.\w!?]+)([(`"' ] *|:['"]?)?#{
        }| *( [:?]\s|=[>~]|[<!>]=|[+\-\|*%,])\s*#{
        }|[{}()\[\]\n;,\|]| end\b/m
      
      StringRE = /(^['"`]$)|^#{percent}$/
      RERE = %r{(?:^|[#{leftop}\w!\s/])\s*(/)}
      HeredocRE = heredoc_handle.to_re
      Symbol = /^:#{name}$/
      Attrs = /\s(c)?(?:attr_(reader|writer|accessor))[( ] *((?::\w+ *,\s*)*:\w+)#{Ender}/
      Include = /\s(include|extend)[( ] *#{mname}/
      AliasMethod = /\salias_method :#{name} *,\s*:#{name}/
      Beginners = /(([#{leftop}\n]?\s*)(if|unless|while|until))#{
        }|(.)?(?:(do|for)|begin|case)/
      EOF = /($0\s*==\s*__FILE__\s*|__FILE__\s*==\s*\$0\s*)?\n/
      BlockOpen = /(?:^\{\s*\||.\{)$/
      Ord = /^\W\?\\?\S$/
      
      MainParseRE = /#{simple
        }|#{call_}|[{}]#{
        }|(^|\n)=begin\b#{
        }|^\s*[;\(]? *(#{mod_def}|#{method_def})#{
        }|:#{name
        }|[^\w#{rightop}'"`\/\\]\?\\?\S#{
        }|#{heredoc
        }|(^|[#{leftop}\n])\s*((if|unless)\b|#{
                                                    }[;\(]? *#{class_def})#{
        }|(^|[\n;])\s*(while|until)\b#{
        }|(^|[#{leftop}\s?])(do|case|begin|for)\b#{
        }|\s(c)?(?:attr_(reader|writer|accessor))[( ] *((?::\w+ *,\s*)*:\w+)#{Ender
        }|\salias_method +:#{name} *,\s*:#{name
        }|\s(include|extend)[( ] *#{mname
        }|(^|[;\s])(#{alias_def}|end|__END__)\b/m
        
      ModDef = mod_def.to_re
      ClassDef = class_def.to_re
      MethodDef = method_def.to_re
      AliasDef = alias_def.to_re
      
      def debug(s)
        $log.debug(:caller=>1) {"#{s.string[0, s.pos].count("\n")+1}:#{s.head.size + s.matched_size - ((s.head+s.matched).reverse.index("\n") || 0)}"}
        $log.debug(@stack, :caller=>1)
        $log.debug(:caller=>1) {Painter.g(s.head+s.matched)}
      end
      
      def Class(s, m)       
        debug(s)       
        _stack = clean_stack
        if _stack[-1] == [:block]
            stack << [:beginner]
        elsif m[1]
            if m[2] =~ /^[@$]/
                stack << [:beginner]
            elsif _stack.any? and _stack[-1][0] == :def
                stack << [:beginner]
            else
                slf = _stack.lasts*'::'
                name = m[2].sub 'self.', ''
                name.sub! 'self', slf
                name = fix_module_name slf, name
                stack << [:singleton, name]
            end
        else
            new = clean_stack.lasts*'::'
            stack << [:class, m[2]]
            name = fix_module_name new, m[3] if m[3]
            new << '::' if new.b
            new << m[2]
            @MethodCache[new] ||= {}
            inherit! new, name if m[3]
        end
      end
      
      def Module(s, m)
        debug(s)       
        stack << [:mod, m[1]]
        @MethodCache[clean_stack.lasts*'::'] = {}
      end
      
      def Method(s, m)
        debug(s)
        _stack = clean_stack(true)
        if _stack[-1] == [:block]
          stack << [:beginner]
        else
          start = s.pos - s.matched[/[^\n]+$/].size
          name = m[1].sub(/::([^:.]+)$/, '.\1')
          name.sub!(/#{_stack.last[1]}\./, 'self.') if _stack.any?
          if name[/^self\.(.+)/]
            stack << [:def, "#{_stack.lasts*'::'}.#$1", start]
          elsif name['.'] and name =~ /^[A-Z]/
            mod, name = name/'.'
            fix_module_name(_stack.lasts*'::', mod) >> '.' >> name
            stack << [:def, name, start]
          else
            prefix = (_stack.any? && _stack[-1][0] == :singleton) ? _stack[-1][1]+'.' : _stack.lasts*'::'+'#'
            stack << [:def, prefix+name, start]
          end
        end
      end
      
      def Alias(s, m)
        debug(s)       
        _stack = clean_stack
        case _stack.any? && _stack[-1][0]
          when false, :def, :block
              return
          when :singleton
              prefix = _stack[-1][1]
              new, old = '.'+m[1], '.'+m[2]
          else
              prefix = _stack.lasts*'::'
              new, old = '#'+m[1], '#'+m[2]
        end
        @MethodCache[prefix][new] = @MethodCache[prefix][old] || "def #{new}(*args)\n  #{old}(*args)\nend"
      end
      
    end if !defined? Defaults
      
    Closers = {'<' => '>', '{' => '}', '[' => ']', '(' => ')'}
    
    def init_instructions
      [
          [/^\#/, lambda {|s, m| s.scan_until(/\n/)}],
          [StringRE, method(:string)],
          
          [/^\{$/, lambda {|s, m| 
            debug(s)
            $log.debug @curls_count
            @curls_count += 1
          }],
          
          [/^\}$/, method(:curl_close)],
          [Ord],
          
          [BlockOpen, lambda {|s, m| 
            debug(s)
            $log.debug @curls_count
            @stack << [:block]
          }],
          
          [ModDef, method(:Module)],
          [ClassDef, method(:Class)],
          [MethodDef, method(:Method)],
          [AliasDef, method(:Alias)],
          [Symbol],
          [RERE, method(:string)],
          [HeredocRE, method(:heredoc)],
          
          [/(^|\n)=begin/, lambda {|s, m| s.scan_until(/\n=end\s*\n/m)}],
          
          [Attrs, lambda {|s, m|
            attr_accessors s, m
            if s.matched =~ / end$/
              end!(s)
            elsif s.matched =~ /[^\?]\}$/
              curl_close
            end
          }],
          
          [Include, lambda {|s, m|
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
          
          [AliasMethod, lambda {|s, m|
            _stack = clean_stack
            if _stack[-1][0] == :class
              new, old = m[1..2]
              prefix = _stack.lasts*'::'
              @MethodCache[prefix][new] = @MethodCache[prefix][old] || "def #{new}(*args)\n  #{old}(*args)\nend"
            end
          }],
          
          [Beginners, lambda {|s, m|
            debug(s)
            $log.debug [m, s.last, s.string[s.last-1,1].to_s]
            if (m[2] and s.last != 0 and m[2].tr(' \t', '').empty? and !(s.string[s.last-1,1].to_s)[/[\n;({\[]/])
            else
              if m[3] == 'if' and @stack.empty? and s.check_until(EOF) and s.matched != "\n"
                throw :EOF
              end
              @stack << [m[5] ? :block : :beginner]
            end
          }],
          
          [/(^|[\s;])end.?/, method(:end!)],
          [/(^|[\s;])__END__/, lambda {|s, m| throw :EOF}]
      ].dup
    end
    
    def initialize(instructions_module=Defaults)
      @MethodCache = {'Object' => {}}
      @ReadPaths = {}
      #extend instructions_module
      self.class.__send__(:include, instructions_module)
      @Instructions = init_instructions
      @MainParseRE = MainParseRE
      add_method_seeker('.get_opts') {|s, args| $log <= args}
    end
    
    def add_instruction(re, &callback)
      @MainParseRE |= re 
      @Instructions << [re, callback]
    end
    
    def add_method_seeker(name, *args, &callback)
      if name.ord == ?.
        pattern = /\w\.(#{name[1..-1]})([(`"' ] *|:['"]?)/
      else
        pattern = /(?:^|[\s#{Leftop}])(#{name})([(`"' ] *|:['"]?)/
      end
      $log <= pattern
      add_instruction(pattern) {|s, m|
        $log << m
        yield s, arguments(s, m)
      }
    end
    
    # Parser methods
    
    def arguments(s, m)
      $panic=true
      debug(s)    
      $panic=false
      $log<<m
      if m[2] =~ /['"`:]/
        s.pos -= 1
        s.matched_size -= 1
        if m[2] =~ /:['"]/
          s.pos -= 1
          s.matched_size -= 1
        end
      end
      arg_list = [m[1]]
      parens = m[2]=='('
      counts = {'}' => 0, ']' => 0, ')' => 0}
      eol = catch(:EOL) {s.each(ArgumentsParseRE, [
          [/^[{\[(]$/, lambda {|s, m| $log<<m;arg_list << m[0];counts[Closers[m[0]]] += 1}],
          [/^[}\])]$/, lambda {|s, m| 
          $log<<m;
            if counts[m[0]] > 0
              counts[m[0]] -= 1
            else
              curl_close if m[0]=='}'
              throw :EOL, :arguments
            end
          }],
          [/[#\n;]| end\b/, lambda {|s, m| $log<<m;
            s.scan_until(/\n/) if m[0] == '#'
            throw :EOL
          }],
          [StringRE, lambda {|s, m| $log<<m;
            str = [s.pos-1, string(s, m)]
            str[1] ? arg_list << s.string[str[0]...str[1]] : arg_list << s.string[str[0]-1..str[0]]
          }],
          [RERE, lambda {|s, m| $log<<m;
            str = [s.pos-1, string(s, m)]
            arg_list << s.string[str[0]...str[1]]
          }],
          [/^ *(?:( [:?]\s|=[>~]|[<!>]=|[+\-\|*%])|,)\s*$/, lambda {|s, m| $log<<m;arg_list << m[1] if m[1]}],
          [/^(\d[\d.]+|:[@$_a-z]\w*|[@$]\w+) *$/, lambda {|s, m| $log<<m;arg_list << m[1]}],
          [/^([@$_a-z][:.\w!?]+)([(`"' ] *|:['"]?)?$/, lambda {|s, m| $log<<m;
            str_beg = s.pos-s.matched_size
            a, eol = arguments(s, m)
            if a
              $log << [a, s.string[str_beg...s.pos]]
              arg_list << s.string[str_beg...s.pos]
            end
            if eol == :arguments
              throw :EOL
            end
          }]
      ])}
      $log << [arg_list, eol]
      [arg_list, eol]
    end
    
    def string(s, m)
      debug(s)
      return if m[1] and s.- == '$'
      opener = m[1] || m[3] || m[5]
      $log.log {"entering #{opener}-quotes, matched as '#{Painter.g s.matched}' at #{s.string[0..s.pos].count("\n")+1}"}
      if opener == m[5]
        closer = opener = m[5].tr('`\'"', '')
        quote_re = /\\|\n#{'\s*' if m[4]}#{closer}/
      else
        closer = Closers[opener] || opener
        quote_re = /\\|#{Regexp.escape closer}/
      end
      openers_cnt = 1
      inner_curls_count = 0
      backslash = false
      quote_re |= /#\{/ if (m[5] and m[5].ord != ?') or closer =~ /[\/"`]/ or (m[2] =~ /[xrQW]/ or m[3])
      instructions = [
        [Ord],
        [/\s*#{Regexp.escape closer}$/, lambda {|s, m|
          if backslash
            backslash = false
            break if s.- == '\\' and m[0] == closer
          end
          if (openers_cnt -= 1) == 0
            $log.log {"exiting through #{closer}-quotes at #{s.string[0...s.pos].count("\n")+1}"}
            throw :EOS 
        else
            $log.log 'decreasing openers count'
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
        $log.log {"#{!backslash ? 'closed' : 'found'} \\ in #{opener}-quotes at #{s.string[0, s.pos].count("\n")+1}"}
        }],
        [/\#\{/, lambda {|s, m| 
          if backslash
            backslash = false
            if s.- == '\\'
              openers_cnt += 1 if closer == '}'
              break
            end
          end
        $log.log "entering curls"
          inner_curls_count += 1
          catch(:inner_out) {s.each(StringParseRE, [
              [/^\#$/, lambda {|s, m| 
              $log.log 'reading comment'
             s.scan_until(/\n/)}],
              [/^\{$/, lambda {|s, m| 
              $log.log "increasing curls count"
              inner_curls_count += 1}],
              [/^\}$/, lambda {|s, m| 
              if (inner_curls_count -= 1) == 0
                $log.log "exiting curls"
                throw :inner_out
              else
                $log.log "decreasing curls count"
              end}],
              [HeredocRE, method(:heredoc)],
              [StringRE, method(:string)],
              [RERE, method(:string)]
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
        $log.log 'increasing openers count'
          openers_cnt += 1
        }]
        $log.debug [quote_re,instructions]
      end
        
      catch(:EOS) {s.each(quote_re, instructions)}
      s.pos
    end
    
    def heredoc(s, m)
      heredoc_list = [m[1..2]]
      catch(:EOL) {s.each(HeredocParseRE, [
          [/[#\n]/, lambda {|s, m| 
            s.scan_until(/\n/) if m[0] == '#'
            heredoc_list.each {|opener| string(s, [nil]*4+opener)}
            throw :EOL
          }],
          [HeredocRE, lambda {|s, m| heredoc_list << m[1..2]}],
          [StringRE, method(:string)],
          [RERE, method(:string)]
      ])}
    end
    
    def curl_close(*)
      if @curls_count == 0
        @stack.pop
      else
        @curls_count -= 1
      end
    end
    
    def end!(s, *)
      debug(s)
      if s.+ !~ /[?!(]/
        exit = @stack.pop
        case exit[0]
          when :def
            prefix, name = exit[1].sharp_split(/[.@#]/, 2)
            if !name
              prefix, name = 'Object', prefix
            end
            if @MethodCache[prefix]
              (@MethodCache[prefix][name] ||= []) << (@path.inline ? [@path, exit[2]...s.pos] : s.string[exit[2]...s.pos])
            end
        end
      end
    end
    
    def attr_accessors(s, m)
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
    end

    def parse_file(path)
      @stack = []
      @path = path
      
      if path.inline
        return if @ReadPaths[path]
        lines = get_lines(path)[0]
        @ReadPaths[path] = true
      else
        lines = path.sharp_split(/\n/)
      end
      if RUBY_VERSION > '1.9'
        ss = StringScanner.new lines.join.force_encoding('UTF-8')
      else
        ss = StringScanner.new lines.join
      end
      
      @curls_count = 0
      catch(:EOF) { ss.each @MainParseRE, @Instructions }
      raise "Can't parse: #{@stack.inspect}, #{ss.string[ss.last..ss.pos].inspect}\nfile:#{path}" if @stack.any?
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
      SCRIPT_LINES__.to_a.select {|d, f| d[path]}.to_a.lasts
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
        raise "If first parameter is a string then it must be of Module{#|.}method form" if !name
      elsif Module === path
        prefix = path.name
        name = ".#{name}"
      else
        prefix = path.class.name
        name = "##{name}"
      end
      if SCRIPT_LINES__.size == @ReadPaths.size and (SCRIPT_LINES__.keys - @ReadPaths.keys).empty?
        puts "nothing was found for #{prefix}#{name}"
      else
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
          else puts
          end
        else
          puts "code for #{prefix}#{name}:"
          print_lines prefix, name, all
        end
      end
    end

  end  
  if !defined? Reader
  Reader = CodeReader.new
  end
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