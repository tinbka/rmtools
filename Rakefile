require 'rake'
require 'lib/rmtools/install'
compile_manifest

RMTOOLS_VERSION = '1.2.0'
begin
    require 'hoe'
    config = Hoe.spec 'rmtools' do
        developer("Shinku", "tinbka@gmail.com")

        self.summary = 'Yet another Ruby applied framework'
        self.description = 'Applied framework primarily for debug and text/arrays/files operation.'
        self.changes = paragraphs_of('README.txt', 5..-1).join("\n\n")
        self.url = 'http://github.com/tinbka'
       
        self.extra_deps = [['rake','>= 0.8.7'], ['activesupport','>= 2.3.8']]
    end
    config.spec.extensions << 'ext/extconf.rb'
rescue LoadError
    STDERR.puts "cannot load the Hoe gem. Distribution is disabled"
rescue Exception => e
    STDERR.puts "cannot load the Hoe gem, or Hoe fails. Distribution is disabled"
    STDERR.puts "error message is: #{e.message}"
end

ruby  = RbConfig::CONFIG['RUBY_INSTALL_NAME']
windoze = RUBY_PLATFORM =~ /mswin32/
make = windoze ? 'nmake' : 'make'

Dir.chdir "ext" do
  unless system "#{ruby} extconf.rb #{ENV['EXTCONF_OPTS']}" and system make
    # don't we have a compiler?
    warn "failed to compile extension, continuing installation without extension"
  end
  if File.file? 'Makefile'
    system "#{make} clean" and FileUtils.rm_f "Makefile"
  end
end unless ext_files_not_modified 'rmtools', RMTOOLS_VERSION