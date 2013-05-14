# encoding: utf-8
begin
  require 'active_record'
  ActiveRecord::Base
  RMTools::require 'active_record', '*'
  # fix for that mystic bug
  #   /usr/lib/ruby/1.8/openssl/ssl-internal.rb:30: [BUG] Segmentation fault
  #   ruby 1.8.7 (2010-08-16 patchlevel 302) [i686-linux]
  if RUBY_VERSION < '1.9.3'
    require 'openssl/ssl'
  else
    require 'openssl'
  end
rescue Exception
  p $!
  nil
end