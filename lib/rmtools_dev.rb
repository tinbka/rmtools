$stderr.puts 'require "rmtools_dev" is deprecated since 2.0.0. Please require "rmtools"'
$stderr.puts "called from #{caller(1).find {|line| line !~ /dependencies.rb/}}"
require 'rmtools'