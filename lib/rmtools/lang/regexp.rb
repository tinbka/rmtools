# encoding: utf-8
RMTools::require 'lang/cyrillic'

class Regexp
  
  def cyr_ic() Regexp.new(source.cyr_ic, options) end
  alias :ci :cyr_ic

end