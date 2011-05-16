# encoding: utf-8
begin
  require 'active_record'
  ActiveRecord::Base
  RMTools::require __FILE__, 'active_record'
  # fix for that mystic bug
  #   /usr/lib/ruby/1.8/openssl/ssl-internal.rb:30: [BUG] Segmentation fault
  #   ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-linux]
  require 'openssl/ssl'
rescue Exception
  p $!
  nil
end