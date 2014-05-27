# encoding: utf-8
RMTools::require 'dev/highlight'
RMTools::require 'dev/logging'
require 'active_support/core_ext/class/attribute'

module RMTools

	# Python-like traceback for exceptions; uses ANSI coloring.
  # In case of any low-level ruby error it may hang up interpreter
  # (although you must have done VERY creepy things for that). If you find 
  # interpreter in hanging up, require 'rmtools_notrace' instead of 'rmtools'
  # or run "Exception.trace_format false" right after require
  #
  #   1:0> def divbyzero
  #   2:1< 10/0 end
  #   => nil
  #   3:0> divbyzero
  #   ZeroDivisionError: divided by 0
  #          from (irb):2:in `divbyzero' <- `/'
  #     >>  10/0 end
  #          from (irb):3
  #     >>  divbyzero

  if RUBY_VERSION < '2'
    IgnoreFiles = %r{#{Regexp.escape $:.grep(%r{/ruby/1\.(8|9\.\d)$})[0]}/irb(/|\.rb$)|/active_support/dependencies.rb$}
  else
    IgnoreFiles = %r{/irb(/|\.rb$)|/active_support/dependencies.rb$}
  end
  
  def format_trace(a)
    return [] if !a.b
    bt, steps, i = [], [], 0
    m = a[0].parse:caller
    # seems like that bug is fixed for now
    #m.line -= 1 if m and m.file =~ /\.haml$/
    while i < a.size
      m2 = a[i+1] && a[i+1].parse(:caller)
      #m2.line -= 1 if m2 and m2.file =~ /\.haml$/
      if !m or m.path =~ IgnoreFiles
        nil
      else
        step = a[i]
        if m.block_level # > 1.9
          step = step.sub(/block (\(\d+ levels\) )?in/, '{'+m.block_level+'}')
        end
        if m and m.func and m2 and [m.path, m.line] == [m2.path, m2.line]
          steps << " -> `#{'{'+m.block_level+'} ' if m.block_level}#{m.func}'"
        elsif m and m.line != 0 and line = RMTools.highlighted_line(m.path, m.line)
          bt << "#{step}#{steps.join}\n#{line}"
          steps = []
        else bt << step
        end
      end
      i += 1
      m = m2
    end
    bt
  end
  
  # disclaimer: Firefox (at least 3.6+) on Windoze does not allow to use file:// protocol T_T
  def format_trace_to_html(a)
    a.map! do |lines|
      caller_string, snippet = lines/"\n"
      caler = caller_string.parse(:caller)
      if caler
        path = caler.path
        lines = ["<a href='#{CGI.escape 'file://'+path}'>#{path}</a>:#{caler.line} in #{caler.func}"]
        lines << RMTools::Painter.clean(snippet) if snippet
        lines * "\n"
      else
        lines
      end
    end
  end
  
  module_function :format_trace, :format_trace_to_html
end

# As for rmtools-1.1.0, 1.9.1 may hung up processing IO while generating traceback
# As for 1.2.10 with 1.9.3 with readline support it isn't hung up anymore

# Usage with Rails.
# Rails raise and rescue a bunch of exceptions during a first load, a reload of code (e.g. in development env) and maybe even some exceptions for each request.
# Thus, trace_format should be set only in a console environment *after* a code is loaded.
# For a web-server environment use RMTools.format_trace for inspect backtrace *after* an exception was rescued.
# Also note that Rails' autoreload of code won't rewrite SCRIPT_LINES__.
class Exception
  alias :set_bt :set_backtrace
  class_attribute :trace_format
  
  # If you also set (e.g. in irbrc file) 
  #   module Readline
  #     alias :orig_readline :readline
  #     def readline(*args)
  #       ln = orig_readline(*args)
  #       SCRIPT_LINES__['(irb)'] << "#{ln}\n"
  #       ln
  #     end
  #   end
  # it will be possible to fetch lines entered in IRB
  # else format_trace would only read ordinally require'd files
  def set_backtrace src
    if format = self.class.trace_format
      src = RMTools.__send__ format, src
    end
    set_bt src
  end
end
  
# This is the most usable setting, I think. Set it in the irbrc, config/initializers or wherever
<<-'example'
if defined? IRB
  class StandardError
    self.trace_format = :format_trace
  end
  
  class SystemStackError
    self.trace_format = nil
  end
end
example