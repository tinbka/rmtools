# encoding: utf-8
RMTools::require 'text/string_simple'
RMTools::require 'enumerable/array_iterators'

class String
    
  def rsplit(splitter=$/, qty=0)
    reverse.split(splitter, qty).reverse.reverses
  end
  
  # Same as split, but without :reject_splitter option keeps splitters on the left of parts
  # with :report_headers option collects all regexp'ed splitters along with result array
    def sharp_split(splitter, *args)
      count, opts = args.fetch_opts [0, :flags], :include_splitter => true
      if !opts[:report_headers] and opts[:include_splitter] and splitter.is Regexp
        return split(/(?=#{splitter.source})/, count)
      end
      a = split(splitter, count)
      return a if !opts[:include_splitter] and !opts[:report_headers]
      skan = nil
      case splitter
        when String
          skan = ([splitter]*a.size).unshift ''
          a = (1...a.size).map {|i| splitter+a[i]}.unshift a[0] if opts[:include_splitter]
        when Regexp
          skan = scan(splitter).unshift ''
          a = (0...a.size).map {|i| skan[i].to_s+a[i]} if opts[:include_splitter]
      end
      opts[:report_headers] ? [a, skan] : a
    end
    
    # Same as sharp_split, but without keeps splitters on the *right* of parts
    def sharp_splitr(splitter, *args)
      count, opts = args.fetch_opts [0, :flags], :include_splitter => true
      a = split(splitter, count)
      return a if !opts[:include_splitter] and !opts[:report_headers]
      skan = nil
      case splitter
        when String
          skan = [splitter]*a.size << ''
          a = (0...a.size-1).map {|i| a[i]+splitter} << a[i] if opts[:include_splitter]
        when Regexp
          skan = scan(splitter) << ''
          a = (0...a.size).map {|i| a[i]+skan[i]} if opts[:include_splitter]
      end
      opts[:report_headers] ? [a, skan] : a
    end
    
    def div(len, *)
      if !len.is Fixnum
        deprecation "Use #sharp_split instead."
        return sharp_split len
      end
      return [self] if len <= 0
      str = dup
      arr = []
      while str.b
        arr << str.slice!(0, len)
      end
      arr
    end
    
  private
    def split_by_syntax(str, maxlen, buflen=0)
      len, add = maxlen - buflen, nil
      [/[^.?!]+\z/, /[^;]+\z/, /[^\n]+/, /\S+\z/, /[^。]+z/, /[^、]+z/].each {|t|
        if !(add = str[t]) or add.size <= len
          return add
        end
      }
      add
    end
    
    def sanitize_blocks!(blocks, opts)
      blocks.reject! {|b| b.empty?} if opts[:no_blanks]
      blocks.strips! if opts[:strips]
      blocks.each {|b| raise Exception, "can't split string by #{terminator} to blocks with max length = #{maxlen}" if b.size > maxlen} if opts[:strict_overhead]
      blocks
    end
    
  public
  #   Base smart-split method
  #   Keep in mind that cyrrilic in 1.8 is 2-byte long as method doesn't use cyrillic lib to not decrease speed.
    def split_to_blocks(maxlen, *opts)
      raise Exception, "Can't split text with maxlen = #{maxlen}" if maxlen < 1
      return [self] if size <= maxlen
      terminator, opts = opts.fetch_opts [nil, :flags], :strict_overhead => true, :no_blanks => true
      blocks = []
      term_re = /[^#{terminator}]+\z/ if terminator and terminator != :syntax
      words, buf = split(opts[:strips] ? ' ' : / /), nil
      while words.b or buf.b
        if terminator and blocks.b and (
          buf_add = if terminator == :syntax
                          split_by_syntax blocks[-1], maxlen, buf.size
                         else blocks[-1][term_re]
                         end.b)
          if buf_add == blocks[-1]
                 blocks.pop
          else blocks[-1] = blocks[-1][0...-buf_add.size]
          end
          buf = buf_add + buf
        end
        if blocks.size == opts[:lines]
          return sanitize_blocks! blocks, opts
        end
        blocks << ''
        if buf
          blocks[-1] << buf
          buf = nil
        end
        while words.b
          buf = words.shift + ' '
          break if blocks[-1].size + buf.size - 1 > maxlen
          blocks[-1] << buf
          buf = nil
        end
      end
      sanitize_blocks! blocks, opts
    end
    
    #   'An elegant way to factor duplication out of options passed to a series of method calls. Each method called in the block, with the block variable as the receiver, will have its options merged with the default options hash provided. '.cut_line 100
    # => "An elegant way to factor duplication out of options passed to a series of method calls..."
    def cut_line(maxlen, *opts)
      terminator, opts = opts.fetch_opts [:syntax, :flags]
      opts[:charsize] ||= RUBY_VERSION < '1.9' && a[0].cyr? ? 2 : 1
      return self if size <= maxlen
      maxlen -= 3
      split_to_blocks(maxlen*opts[:charsize], terminator, :strips => true, :strict_overhead => false, :lines => 1)[0][0, maxlen].chomp('.') + '...'
    end
    
    #   puts 'An elegant way to factor duplication out of options passed to a series of method calls. Each method called in the block, with the block variable as the receiver, will have its options merged with the default options hash provided.  '.split_to_lines 50
    #    produces:
    #   An elegant way to factor duplication out of
    #   options passed to a series of method calls. Each
    #   method called in the block, with the block
    #   variable as the receiver, will have its options
    #   merged with the default options hash provided.
    #
    # This method is use cyrillic lib only to detect char byte-length
    # options: charsize, no_blanks, strips
    def split_to_lines(maxlen, *opts)
      raise Exception, "Can't break text with maxlen = #{maxlen}" if maxlen < 1
      opts = opts.fetch_opts :flags, :strips=>true
      a = split("\n")
      opts[:charsize] ||= RUBY_VERSION < '1.9' && a[0].cyr? ? 2 : 1
      a.map {|string| string.strip.split_to_blocks(maxlen*opts[:charsize], opts.merge(:strict_overhead => false))}.flatten*"\n"
    end
  
end