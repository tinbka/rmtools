module RMTools
  module Extender
  private
  
    # Один файл в папке расширения — это норма
    def __extend__(method, target, addition)
      ext = target # ActiveRecord
      ext << "::#{by}" if by # ActiveRecord::Connection
      path = "#{name}/ext/#{ext}".underscore # rmtools/ext/active_record/connection
      
      if require path
        target = Object.const_get target # ::ActiveRecord
        extender = const_get ext # ActiveRecord::Connection
        target.__send__ method, extender
      end
    end

    def extend!(target, by: nil)
      __extend__ target.to_s, by && by.to_s, :extend
    end

    def include_in!(target, by=nil)
      __extend__ target.to_s, by && by.to_s, :include
    end

    def sugar!(targets, by: nil)
      path = "#{name}/sugar/#{by}".underscore # rmtools/sugar/dictable
      
      require path
      extender = Sugar.const_get by # Sugar::Dictable
      Array(targets).each {|target|
        target = Object.const_get target # ::Hash
        target.__send__ :extend, extender
      }
    end
    
  end
end