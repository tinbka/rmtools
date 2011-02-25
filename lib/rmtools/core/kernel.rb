# encoding: utf-8
module Kernel
  
  # re-require
  def require!(file)
    %w{.rb .so .dll}.each {|ext| $".delete "#{file}#{ext}"}
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
    caller(0)[0] =~ /^#{file}:/
  end
  
end