require 'rake'
require './lib/rmtools/setup'
compile_manifest

begin
    require 'hoe'
    config = Hoe.new('rmtools', '1.0.0') do |h|
        h.developer("Shinku Templar", "tinbka@gmail.com")

        h.summary = 'Yet another Ruby applied framework'
        h.description = h.paragraphs_of('README.txt', 2..3).join("\n\n")
        h.changes = h.paragraphs_of('History.txt', 0..1).join("\n\n")
        h.url = 'http://github.com/tinbka'
       
        h.extra_deps << ['rake','>= 0.8.7']
        h.extra_deps << ['activesupport','>= 2.3.5']
    end
    config.spec.extensions << 'ext/extconf.rb'
rescue LoadError
    STDERR.puts "cannot load the Hoe gem. Distribution is disabled"
rescue Exception => e
    STDERR.puts "cannot load the Hoe gem, or Hoe fails. Distribution is disabled"
    STDERR.puts "error message is: #{e.message}"
end

ruby  = RbConfig::CONFIG['RUBY_INSTALL_NAME']
windoze = PLATFORM =~ /mswin32/
make = windoze ? 'nmake' : 'make'

Dir.chdir "ext" do
  unless system "#{ruby} extconf.rb #{ENV['EXTCONF_OPTS']}" and system make
    # don't we have a compiler?
    warn "failed to compile extension, continuing installation without extension"
  end
  if File.file? 'Makefile'
    system "#{make} clean" and FileUtils.rm_f "Makefile"
  end
end unless ext_files_not_modified
  