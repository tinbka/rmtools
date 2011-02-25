# encoding: utf-8
class Regexp
  
  def | re
    Regexp.new(source+'|'+re.source, options | re.options)
  end
  
  def in string
    string =~ self
  end
  
end