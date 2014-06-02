 # encoding: utf-8
RMTools::require 'text/string_parse'

module RMTools
  class URI
    __init__
    attr_reader :protocol, :host, :port, :path, :query, :anchor
    
    def initialize(url)
      @parsed = url.parse :uri
      @protocol, @host, @port, @path, @query, @anchor = @parsed.values_at *%w[protocol host port path query anchor]
    end
    
    def to_hash
      @parsed
    end
    
    def root
      "#{@protocol.present? ? @protocol+'://' : ''}#@host#{@port && 80 != @port ? ':'+@port : ''}"
    end
    
    def fullpath
      "#{@path.present? ? @path : '/'}#{@query != {} ? '?'+@query.urlencode : ''}"
    end
    alias :pathname :fullpath
    
    def ext
      @path.rsplit('.', 2)[1]
    end
    
    
    def ext=(val)
      @path = "#{@path.rsplit('.', 2)[0]}#{val.present? ? '.'+val : ''}"
    end
    
    def protocol=(val)
      @protocol = val.to_s[/[^:]+/]
    end
    
    def host=(val)
      @host = val.to_s[/[^:]+/]
    end
    
    def port=(val)
      @port = val.to_s.to_i.b
    end
    
    def path=(val)
      @path = val.to_s[/[^?#]+/]
    end
    
    def query=(hash_or_str)
      @query = Hash === hash_or_str ? hash_or_str : (hash_or_str.to_s[/[^?#]+/] || '').to_params
    end
    
    def anchor=(val)
      @anchor = val.to_s[/[^#]+/]
    end
    
    
    def to_s
      "#{root}#{fullpath}#{@anchor.present? ? '#'+@anchor : ''}"
    end
    alias :href :to_s
  
    def inspect
      to_s.inspect
    end
  
  end
end