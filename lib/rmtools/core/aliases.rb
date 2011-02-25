# encoding: utf-8
class Object
  alias :resto :respond_to?
  alias :requrie :require # most frequent typo, lol
end

class String
  if !method_defined? :/
    alias :/ :split 
  end
end