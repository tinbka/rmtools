# encoding: utf-8
# String#to_proc
#
# See http://weblog.raganwald.com/2007/10/stringtoproc.html ( Subscribe in a reader)
#
# Ported from the String Lambdas in Oliver Steele's Functional Javascript
# http://osteele.com/sources/javascript/functional/
#
# This work is licensed under the MIT License:
#
# (c) 2007 Reginald Braithwaite
# Portions Copyright (c) 2006 Oliver Steele


class String
  unless ''.respond_to?(:to_proc)
=begin original definition:
    def to_proc &block
      params = []
      expr = self
      sections = expr.split(/\s*->\s*/m)
      if sections.length > 1 then
          eval sections.reverse!.inject { |e, p| "(Proc.new { |#{p.split(/\s/).join(', ')}| #{e} })" }, block && block.binding
      elsif expr.match(/\b_\b/)
          eval "Proc.new { |_| #{expr} }", block && block.binding
      else
          leftSection = expr.match(/^\s*(?:[+*\/%&|\^\.=<>\[]|!=)/m)
          rightSection = expr.match(/[+\-*\/%&|\^\.=<>!]\s*$/m)
          if leftSection || rightSection then
              if (leftSection) then
                  params.push('$left')
                  expr = '$left' + expr
              end
              if (rightSection) then
                  params.push('$right')
                  expr = expr + '$right'
              end
          else
              self.gsub(
                  /(?:\b[A-Z]|\.[a-zA-Z_$])[a-zA-Z_$\d]*|[a-zA-Z_$][a-zA-Z_$\d]*:|self|arguments|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/, ''
              ).scan(
                /([a-z_$][a-z_$\d]*)/i
              ) do |v|  
                params.push(v) unless params.include?(v)
              end
          end
          eval "Proc.new { |#{params.join(', ')}| #{expr} }", block && block.binding
      end
    end
=end

    RMTools::String_to_proc_cache = {}
    def to_proc &block
      # improving performance
      if proc = RMTools::String_to_proc_cache[[self, block]]
        return proc
      end
      params = []
      expr = self
      sections = expr.split(/\s*->\s*/m)
      proc = 
      if sections.length > 1
          str = sections.reverse!.inject { |e, p| "(Proc.new { |#{p.split(/\s/).join(', ')}| #{e} })" }
          (proc = eval str, block && block.binding).string = str
          proc
      elsif expr.match(/\b_\b/)
          Proc.eval "|_| #{expr}", block && block.binding
      else
          leftSection = expr.match(/^\s*(?:[+*\/%&|\^\.=<>\[]|!=)/m)
          rightSection = expr.match(/[+\-*\/%&|\^\.=<>!]\s*$/m)
          if leftSection || rightSection
              if leftSection
                  params.push('__left')
                  expr = '__left' + expr
              end
              if rightSection
                  params.push('__right')
                  expr = expr + '__right'
              end
          else
              params = gsub(/(?:\b[A-Z]|\.[a-zA-Z_$])[a-zA-Z_$\d]*|[a-zA-Z_$][a-zA-Z_$\d]*:|self|arguments|'(?:[^'\\]|\\.)*'|"(?:[^"\\]|\\.)*"/, ''
              ).scan(
                /([a-z_$][a-z_$\d]*)/i
              ).uniq
          end
          Proc.eval "|#{params.join(', ')}| #{expr}", block && block.binding
      end
      RMTools::String_to_proc_cache[[self, block]] ||= proc
    end
    
  end
end


