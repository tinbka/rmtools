# encoding: utf-8
module Kernel
  
  # re-require
  def require!(file)
    [file, File.expand_path(file)].find {|path|
      ['.rb', '.so', '.dll', ''].find {|ext| 
        $".delete "#{file}#{ext}"
      }
    } || $".del_where {|path| path[%r{/#{file}(.rb|.so|.dll)?$}]}
    require file
  end

  def obtained(obj, &func)
    if obj.is Proc
      if obj.arity == 0
        func.call obj.call
      else # obj is a function receiving another function
        obj.call &func
      end
    else func.call obj
    end
  end
  
  def TypeError! given, *expected
    "invalid argument type #{given.class.name}, expected #{expected*' or '}"
  end
    
  def executing? file=$0
    caller[0] =~ /^#{file}:/
  end
  
  def whose?(method, *opts)
    opts = *opts.get_opts([:flags], :ns => :public)
    opts[:modules] ||= opts[:mod]
    checker = :"#{opts[:ns]}_method_defined?"
    if Array === method
      methods = method.to_syms
    else 
      methods = [method = method.to_sym]
    end
    if defined? ActiveSupport::JSON::CircularReferenceError
      ActiveSupport::JSON.__send__ :remove_const, :CircularReferenceError
    end
    classes = {}
    
    methods.each {|m|
        classes[m] = {Object => true} if Object.send checker, m and (
          !opts[:modules] or 
          Object.included_modules.select {|mod| (checker[m] ||= {})[mod] = true if mod.__send__ checker, m}.empty?
        )
    }
    methods -= classes.keys
    return classes.map_values {|h| h.keys} if methods.empty?
    
    klass = opts[:modules] ? Module : Class
    ObjectSpace.each_object {|o| 
      methods.each {|m| (classes[m] ||= {})[o] = true if o.name != '' and o.__send__ checker, m} if klass === o
    }
    classes.map_values! {|h| 
      if !opts[:descendants]
        h.each {|c, b| h[c] = nil if (c.is Class and h.key? c.superclass) or (opts[:modules] and c.included_modules.find {|a| h.key? a})}
      end
      h.map {|c,b| b && c}.compact
    }
    
    Array === method ? classes : classes[method]
  end
  
  def thread(&block)
    Thread.new(&block)
  end
  
end