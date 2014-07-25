module RMTools
  module String
    module Helpers
      
      def /(*args)
        split(*args)
      end
      
      def inline
        index("\n").nil?
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
      
      
      # make simple strings readable by FTS engines and make results more cacheable by key-value dbs
      def to_search
        gsub(/[\0-\/:-@\[-`{-~ \s]/, ' ').strip.squeeze(' ').fdowncase
      end
      
      # remove empty strings from html output
      def squeeze_newlines
        gsub(/\s+\n+/, "\n").squeeze("\n")
      end
      
    end
  end
end