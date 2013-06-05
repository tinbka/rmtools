# encoding: utf-8
require 'set'
RMTools::require 'enumerable/set_ops'

class Set
  alias :uniq :dup
  include RMTools::SmarterSetOps
end