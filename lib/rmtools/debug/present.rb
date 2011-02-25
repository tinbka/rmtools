# encoding: utf-8
class Object
  
  def present
    [true, false, nil, Numeric, String, Regexp].each {|klass| return puts inspect if klass === self}
    Hash[readable_variables.map {|v| [":#{v}", __send__(v)]}].present
  end
  
end

class Array
  
  def present(inspect_string=nil)
    res = "[ "
    indent = (size-1).to_s.size
    res << map_with_index {|k,i|
      "#{i.to_s.rjust(indent)}: #{(k.is String and !inspect_string) ? k : k.inspect}"
    }*"\n  "
    res << "]"
    puts res
  end
  
end

class Hash
  
  def present(inspect_string=nil)
    str = "{ "
    sorted = sort rescue to_a.sort_by_to_s
    str << sorted.map {|k,v|
      "#{(k.is String and !inspect_string) ? k : k.inspect} => #{(v.is String and !inspect_string) ? v : v.inspect},"
    }*"\n  "
    str << "}"
    puts str
  end
  
end


