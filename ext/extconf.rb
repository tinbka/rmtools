if RUBY_VERSION < "2"
  require 'mkmf'

  CONFIG['CC'] = "g++"
  if RUBY_VERSION >= "1.9"
      $CFLAGS += " -DRUBY_IS_19"
  end

  dir_config("ruby19")
  create_makefile("rmtools")
else
  # Create a dummy Makefile, to satisfy Gem::Installer#install
  # http://stackoverflow.com/questions/17406246/native-extensions-fallback-to-pure-ruby-if-not-supported-on-gem-install
  mfile = open("Makefile", "wb")
  mfile.puts '.PHONY: install'
  mfile.puts 'install:'
  mfile.puts "\t" + '@echo "Extensions not installed, falling back to pure Ruby version."'
  mfile.close
end