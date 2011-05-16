RMTools::require 'text/string_scanner'

class Regexp
  
  # reverses a regexp just like an ordinal string so one can use it for lookbehind
  #     /abc(?=>d.+f){1,10}(?=>[^g+h-j]*\w+?)*?$/.reverse
  ### => /^(?=\w+?[^g+h-j]*>)*?(?=f.+d>){1,10}cba/
  def reverse
    return self if source.size == 1 or source.size == 2 && (source.ord == ?\\ or source[0] == source[1])
    new = []
    bs = klass = count = nil
    group_marks = []
    oppose = {'('=>')', ')'=>'(', '^'=>'$', '$'=>'^'}
    borders = {'Z'=>'\A', 'A'=>'\Z'}
    ext = options&2 != 0
    StringScanner(source).each(/./) {|s|
      if (m = s.matched) == '\\'
        (klass || new) << '\\' if !(bs = !bs)
      else
        if bs
          if !klass and m =~ /\d/
            if m != '0' and s.+ !~ /\d/
              raise RegexpError, "there is no meaning in use of groups \\#{m} inside of reversed regexp at #{s.pos-1}"
            else
              chars = s.check_until(/\D/)[0..-2]
              new << ((m == '0' ? m : '0' << m) << chars).to_i(8).chr
              s.pos += chars.size
            end
          elsif !klass and m == 'x'
            chars = s.check_until(/[^a-f\d]/)[0..-2]
            new << chars.to_i(16).chr
            s.pos += chars.size
          else
            (klass || new) << ((b = borders[m]) ? b.dup : '\\' << m)
          end
        elsif ext and m =~ /\s/
          next
        elsif ext and m == '#'
          s.scan_until(/\n\s*/)
        else case m.ord
          when ?[;      klass = ''
          when ?];      new << "[#{klass}]"; klass = nil
          when ?{;      klass ? klass << m : count = ''
          when ?};      klass ? klass << m : _find_paren(new) << "{#{count}}"; count = nil
          when ?^, ?$; klass ? klass << m : new << oppose[m]
          when ?+, ?*; klass ? klass << m : _find_paren(new) << m 
          when ??
            if new.last == ')'
              group_marks << s.scan_until(/./)
            else klass ? klass << m : _find_paren(new) << m 
            end
          when ?)
            gm = group_marks.pop
            gm ? new << ('(?' << gm) : (klass || new) << '('
          else (count || klass || new) << ((op = oppose[m]) ? op.dup : m)
          end
        end
        bs = false
      end
    }
    new.reverse.join.to_re
  end
  
private
  def _find_paren(new)
    if new.last.ord == ?(
      n = 0
      new.rfind {|e| e.ord == ?( ? !(n+=1) : (e.ord == ?) && (n-=1) == 0)}
    else
      new.last
    end
  end
  
end