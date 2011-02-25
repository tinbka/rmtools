# encoding: utf-8
require 'cgi'

class String

  # with default delimiters - inversion of #urlencode
  def to_hash(unscp=true, params_delim='&', k_v_delim='=')
    params = split(params_delim)
    h = {}
    params.each {|par|
      str = par.split(k_v_delim, 2)
      if unscp
        h[CGI.unescape(str[0]) || ''] = CGI.unescape(str[1] || '')
      else
        h[str[0]] = str[1]
      end
    }
    h
  end
  
  # inversion of #to_json
  # active support activesupport
  def from_json
    ActiveSupport::JSON.decode self
  end

end