# encoding: utf-8
RMTools::require 'lang/cyrillic'

class Regexp
  
  if RUBY_VERSION > '1.9'
    def ci; self end
  else
    def ci; Regexp.new(source.cyr_ic, options) end
  end

end