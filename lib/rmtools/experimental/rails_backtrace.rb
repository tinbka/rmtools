# encoding: utf-8
module RMTools
  def highlighted_line_html file, line
    if File.file?(file)
      "   >>   <a style=\"color:#0A0; text-decoration: none;\"#{
        " href=\"http://#{
          defined?(DEBUG_SERVER) ? DEBUG_SERVER : 'localhost:8888'
        }/code/#{CGI.escape CGI.escape(file).gsub('.', '%2E')}/#{line}\""
      }>#{read_lines(file, line.to_i).chop}</a>" 
    end
  end

  def format_trace_html a
    bt, calls, i = [], [], 0
    m = a[0].match(/^(.+):(\d+)(?::in `([^']+)')?$/)
    while i < a.size
      m2 = a[i+1] && a[i+1].match(/^(.+):(\d+)(?::in `([^']+)')?$/)
      if m and m[3] and m2 and m[1..2] == m2[1..2]
        calls.unshift " <- `#{m[3]}'"
      elsif m and m[1] !~ /\.gemspec$/ and line = highlighted_line_html(*m[1..2])
        bt << "#{a[i]}#{calls.join}\n#{line}"
        calls = []
      else bt << a[i]
      end
      i += 1
      m = m2
    end
    bt
  end
end