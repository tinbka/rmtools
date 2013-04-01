# encoding: utf-8
class String
  
  def inline
    index("\n").nil?
  end
    
  def lchomp(match=/\r\n?/)
    if index(match) == 0
      self[match.size..-1]
    else
      self.dup
    end
  end

  def lchomp!(match=/\r\n?/)
    if index(match) == 0
      self[0...match.size] = ''
      self
    end
  end
    
  def until(splitter=$/)
    split(splitter, 2)[0]
  end
  alias :till :until
    
  def after(splitter=$/)
    split(splitter, 2)[1]
  end
    
  # %{blah blah
  #  wall of text in the interpreter
  # oh it's too bulky; may be we should
  # save this text into variable
  # blah blah} >> (str='') 
  # saved!
  def >>(str)
    str.replace(self + str)
  end
    
  # Fast search for highlighting purposes
  def find_with_offsets text, offset
    index = index(text)
    start = [0, index - offset].max
    _end = index + text.size
    [self[start...index], text, self[_end, offset]]
  end
    
  # 'filename.txt'.bump!.bump!
  # => "filename.txt.2"
  # 'filename.txt'.bump!.bump!.bump!('_')
  # => "filename.txt.2_1"
  # 'filename.txt'.bump!.bump!.bump!('_').bump!
  # => "filename.txt.2_1.1"
  def bump!(splt='.')
    replace bump_version splt
  end
    
  def bump_version(splt='.')
    re = /(?:(\d*)#{Regexp.escape splt})?/
    s = File.split self
    s[0] == '.' ?
      s[1].reverse.sub(re) {$1?"#{$1.to_i+1}#{splt}":"1#{splt}"}.reverse : 
      File.join(s[0], s[1].reverse.sub(re)  {$1?"#{$1.to_i+1}#{splt}":"1#{splt}"}.reverse)
  end
  alias :next_version :bump_version
    
  def to_re(esc=false)
    Regexp.new(esc ? Regexp.escape(self) : self)
  end
  
  #    "b ц ~ \255 秀".bytes
  ### => ["62", "20", "d1", "86", "20", "7e", "20", "ad", "20", "e7", "a7", "80"]
  #def bytes
  #  arr = []
  #  each_byte {|b| arr << b.hex}
  #  arr
  #end
  #
  # this method defined in Enumerable and returns Enumerable::Enumerator that should be converted to array of integers, not hex-strings
  
  if RUBY_VERSION < '1.9'
    def symbols_count
      unpack('U*').size
    end
  else
    def symbols_count
      size
    end
  end
  
  
  # make simple strings readable by FTS engines and make results more cacheable by key-value dbs
  def to_search
    gsub(/[\0-\/:-@\[-`{-~ \s]/, ' ').strip.squeeze(' ').fdowncase
  end
  
  # remove empty strings from html output
  def squeeze_newlines
    gsub(/\s+\n+/, "\n").squeeze("\n")
  end
  
  # polymorphic helper
  def recordize(whiny=true)
    classname, id = split('#')
    unless id
      if whiny
        raise ArgumentError, "Could not find record by string: #{inspect}"
      else return false
      end
    end
    model = classname.constantize
    model.respond_to?(:get) ?
      model.get(id) : 
      model.where(:id => id).first
  end
  alias :to_record :recordize
  
end