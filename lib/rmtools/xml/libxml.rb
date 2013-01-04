# encoding: utf-8
require 'xml'
RMTools::require 'xml/{xpath,finders,node,document,string}'
RMTools::require 'enumerable/common'

module LibXML::XML
  Error.reset_handler
  
  class XPath::Object
    include Enumerable
  end
end