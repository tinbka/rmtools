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
      "#{RMTools::Painter.w(i.to_s.rjust(indent))}: #{(k.is String and !inspect_string) ? k : k.inspect}"
    }*"\n  "
    res << "]"
    puts res
  end
  
  # draw array as box
  # just calls #inspect if max element.inspect size is greater than console width
  def as_box(opts={})
    opts = {:max_cols => Inf, :padding => 0}.merge opts
    return inspect unless cols = ENV['COLUMNS']
    cols = cols.to_i
    cell_size = map {|e| e.inspect.csize}.max + opts[:padding]*2
    if n = [(1..cols/2).max {|i| i*(cell_size+1) < cols}, opts[:max_cols]].min
      table = div(n)
      border = '+'+('-'*cell_size+'+')*n
      need_lb = border.size < cols
      border << "\n" if need_lb
      last_border = table.last.size == n ? 
        border : 
        '+'+('-'*cell_size+'+')*table.last.size + '-'*((cell_size+1)*(n-table.last.size)-1) + '+'
      table.map {|rows| 
        str = '|'+rows.map {|cell| cell.inspect.ccenter(cell_size)}*'|'+'|'
        str << ' '*((cell_size+1)*(n-rows.size)-1)+'|' if rows.size < n
        border + str + ("\n" if need_lb)
      }.join + last_border
    else inspect
    end
  end
  
end

class Hash
  
  def present(inspect_string=nil)
    str = "{ "
    sorted = sort rescue to_a.sort_by_to_s
    str << sorted.map {|k,v|
      "#{RMTools::Painter.w((k.is String and !inspect_string) ? k : k.inspect)} => #{(v.is String and !inspect_string) ? v : v.inspect},"
    }*"\n  "
    str << "}"
    puts str
  end
  
end


