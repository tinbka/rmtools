# encoding: utf-8
begin
  require 'active_record'
  ActiveRecord::Base
  RMTools::require __FILE__, 'active_record'
rescue Exception
  nil
end