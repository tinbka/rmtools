# encoding: utf-8
class Array
  
  def dump(depth=5)
    res = "[ "
    res << map_with_index {|j, i|
      j = 'nil' if j.nil?
      "%0*d: %s、"%[i, (size-1).to_s.size, dump_recurse(j,0,depth)]
    }*"\n  "
    res << "]\n"
  end
  
end

class Hash
  
  def dump(depth=5)
    res = "{ "
    res << map {|i, j|
      i = 'nil' if i.nil?
      j = 'nil' if j.nil?
      "%0*s => %s、\n"%[i, keys.to_ss.max, dump_recurse(j,0,depth)]
    }*"\n  "
    res << "}\n"
  end
  
end


