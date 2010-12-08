class Array
  
  def fetch_opts(defaults=[], opts={})
    if opts and self[-1].is(Hash) and !defaults[size-1].is(Hash)
      opts = opts.merge pop
    end
    each_index {|i| import(defaults, i) if self[i] == :def}
    defaults.slice! 0, size
    concat defaults << opts
  end
  alias :get_opts :fetch_opts

  def valid_types(pattern_ary)
    each_with_index.find {|var, i|
      pattern = pattern_ary[i]
      if pattern.is Array
             pattern.find {|j| !(pattern[j] === var[i])}
      else !(pattern === var[i])
      end
    }
  end
  
end

