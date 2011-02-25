# encoding: utf-8
module RMTools

  def dump_recurse(obj, depth, maxdepth)
    res = ''
    case obj
      when Hash
        if depth <= maxdepth
          res = "{\n"
          obj.each { |i, j|
            i = i.inspect unless i.is_a? String
            childinfo = dump_recurse(j,depth+1,maxdepth)
            res << "%s  %s => %s、\n"%[("  "*depth), i, childinfo]
          }
          res << "  "*depth+"  }"
        else
          res = obj.inspect
        end
        res
      when Array
        if depth <= maxdepth
          res = "[\n"
          obj.each_with_index { |j, i|
            childinfo = dump_recurse(j,depth+1,maxdepth)
            res << "%s  %0*d: %s、\n"%[("  "*depth), (obj.size-1).to_s.size, i, childinfo]
          }
          res << "  "*depth+"  ]"
        else
          res = obj.inspect
        end
        res
      when String then obj
      else obj.inspect
    end
  end
  
end
  
module Enumerable
  
    def dump(depth=5)
      RMTools.dump_recurse self, 0, depth
    end

end