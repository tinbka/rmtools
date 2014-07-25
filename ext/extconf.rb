require 'mkmf'
CONFIG['CC'] = "g++"
dir_config("ruby")
create_makefile("rmtools")