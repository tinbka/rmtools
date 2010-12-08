# encoding: utf-8
module RMTools
    
  def reports(w, b) w.reports(b) end
  
end

module Enumerable
    
  def dump_recurse(obj, depth, maxdepth)
    res = ''
    case obj
      when Hash
        if depth <= maxdepth
          res = "{\n"
          obj.each { |i, j|
            i = 'nil' if i.nil?
            j = 'nil' if j.nil?
            childinfo = dump_recurse(j,depth+1,maxdepth)
            res << "%s\t%s => %s、\n"%[("\t"*depth), i, childinfo]
          }
          res << "\t"*depth+"  }"
        else
          res = obj.inspect
        end
        res
      when Array
        if depth <= maxdepth
          res = "[\n"
          obj.each_with_index { |j, i|
            j = 'nil' if j.nil?
            childinfo = dump_recurse(j,depth+1,maxdepth)
            res << "%s\t%0*d: %s、\n"%[("\t"*depth), (obj.size-1).to_s.size, i, childinfo]
          }
          res << "\t"*depth+"  ]"
        else
          res = obj.inspect
        end
        res
      when String then obj
      else obj.inspect
    end
  end  
  
  def urlencode
    map {|k, v| next if !v
      k, v = k.to_s, v.to_s
      if v =~ /&/
        v = v/'&'
        v.map {|val| "#{CGI.escape(k)}=#{CGI.escape(val)}"} * '&'
      elsif k =~ /&/
        k = k/'&'
        k.map {|key| "#{CGI.escape(key)}=#{CGI.escape(v)}"} * '&'
      else
        "#{CGI.escape(k)}=#{CGI.escape(v)}" 
      end
    } * '&'
  end
  
end

class Object
  
  def present
    Hash[readable_variables.map {|v| [":#{v}", __send__(v)]}].present
  end
  
end

class Array
  
  def dump(depth=5)
    res = "[ "
    res << map_with_index {|j, i|
      j = 'nil' if j.nil?
      "%0*d: %s、"%[i, (size-1).to_s.size, dump_recurse(j,0,depth)]
    }*"\n  "
    res << "]\n"
  end
  
  def present(inspect_string=nil)
    res = "[ "
    indent = (size-1).to_s.size
    res << map_with_index {|k,i|
      "#{i.to_s.rjust(indent)}: #{(k.is String and !inspect_string) ? k : k.inspect}"
    }*"\n  "
    res << "]"
    puts res
  end
  
    def reports b
      map {|s| b.eval "\"#{s.gsub('"'){'\"'}} = \#{(#{s}).inspect}\""} * '; '
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
  
  def present(inspect_string=nil)
    str = "{ "
    sorted = sort rescue(to_a.sort_by_to_s)
    sorted.each {|k,v|
      "#{(k.is String and !inspect_string) ? k : k.inspect} => #{(v.is String and !inspect_string) ? v : v.inspect},"
    }*"\n  "
    str << "}"
    puts str
  end
  
end

class String

  # with default delimiters - inversion of #urlencode
  def to_hash(unscp=true, params_delim='&', k_v_delim='=')
    params = split(params_delim)
    h = {}
    params.each {|par|
      str = par.split(k_v_delim, 2)
      if unscp
        h[CGI.unescape(str[0]) || ''] = CGI.unescape(str[1] || '')
      else
        h[str[0]] = str[1]
      end
    }
    h
  end
  
  # inversion of #to_json
  # works only with activesupport ^_^"
  def from_json
     ActiveSupport::JSON.decode self
  end
    
  def reports b
    split(' ').map {|s| b.eval "\"#{s.gsub('"'){'\"'}} = \#{(#{s}).inspect}\""} * '; '
  end

end

class Integer
  
  def to_apprtime(t=nil)
    if t
      if t.in [:minutes, :min, :m]
        "#{self/60} minutes"
      elsif t.in [:hours, :h]
        "#{self/3600} hours"
      elsif t.in [:days, :d]
        "#{self/86400} days"
      end
    elsif self < 60
      "#{self} seconds"
    elsif self < 3600
      "#{self/60} minutes"
    elsif self < 86400
      "#{self/3600} hours"
    else
      "#{self/86400} days"
    end
  end
  
  def bytes(t=nil)
    if t
      if :kb == t
        sprintf "%.2fkb", to_f/1024
      elsif :mb == t
        sprintf "%.2fmb", to_f/1048576
      elsif :gb == t
        sprintf "%.2fmb", to_f/1073741824
      end
    elsif self < 1024
      "#{self}b"
    elsif self < 1048576
      sprintf "%.2fkb", to_f/1024
    elsif self < 1073741824
      sprintf "%.2fmb", to_f/1048576
    else
      sprintf "%.2fmb", to_f/1073741824
    end
  end

end
