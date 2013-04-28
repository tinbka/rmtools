SCRIPT_LINES__ = {} unless defined? SCRIPT_LINES__
$__MAIN__ = self
require 'active_support'
require 'rmtools/require'
%w[version core enumerable text time functional
  conversions lang rand console
  fs db xml dev
  ../rmtools.so
].each {|file| RMTools::require file}
class Object; include RMTools end