require 'rmtools/ext/russian'
require_relative 'russian/transform'
require_relative 'russian/date_time'

module RMTools
  module String
    module Russian
      
      def self.extended(string)
        string.class_eval {
          include RMTools::Russian
          include Detect
          include Transform
          include DateTime
        }
      end
        
      module Detect
        
        def caps?
          self =~ /^[А-ЯЁA-Z][А-ЯЁ\d A-Z]+$/
        end
        
        def cyr?
          self !~ /[^А-пр-ёЁ]/
        end
        
      end
      
    end
  end
end
