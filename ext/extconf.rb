require 'mkmf'

CONFIG['CC'] = "g++"
if RUBY_VERSION >= "1.9"
    $CFLAGS += " -DRUBY_IS_19"
end

$LDFLAGS += " -module"

dir_config("ruby19")
create_makefile("rmtools")

