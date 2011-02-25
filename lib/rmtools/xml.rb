# encoding: utf-8
begin
  require 'xml'
  LibXML::XML
  RMTools::require __FILE__, 'libxml'
rescue Exception
  nil
end