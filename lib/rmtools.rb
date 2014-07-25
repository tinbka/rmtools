require 'set'
require 'scanf'
require 'strscan'
require 'active_support'
require 'rmtools.so'
require 'rmtools/dependencies/extender'
require 'rmtools/version'
  
module RMTools
  extend Extender
  acronym!
  
  # Один файл в папке расширения — это норма
  def self.__extend__(method, const_name, addition)
    path = 'rmtools/ext/' + const_name.underscore # rmtools/ext/active_record
    path << '/' + by.underscore if by # rmtools/ext/active_record/connection
    
    if require path
      extender = const_get const_name # ActiveRecord
      extender = extender.const_get by if by # ActiveRecord::Connection
      target = Object.const_get const_name # ::ActiveRecord
      
      target.__send__ method, extender
    end
  end

  def self.extend!(const_name, by: nil)
    __extend__ const_name.to_s, by && by.to_s, :extend
  end

  def self.include_in!(const_name, by=nil)
    __extend__ const_name.to_s, by && by.to_s, :include
  end
  
  # Остановимся на том, чтобы включать здесь расширения
  # самого верхнего уровня, а остальные — в расширителях.
  # Тогда процесс расширения будет самодескриптивным
  # ровно настолько, наколько он может быть понятым
  # при текущей степени углубления в lib.
  def self.load_active_record(printerr=true)
    require 'active_record'
    #require 'openssl'
    extend! :ActiveRecord, by: :Connection
    extend! 'ActiveRecord::Base'
  rescue LoadError
    if printerr
      warn "Could not load ActiveRecord gem, ActiveRecord extension was not loaded"
    end
  end
  
  load_active_record false
  
  include_in! :String, :Encoding
  include_in! :String, :Helpers
  include_in! :String, :IP
  include_in! :String, :Parsers
  include_in! :String, :Rand and
    extend! :String, by: :RandClassMethods
  include_in! :String, :Reversed
  extend! :String, by: :Russian
  include_in! :String, :Splitters
  
  include_in! :Object, :Compare
end
  

class Object
  include RMTools::Helpers
  include RMTools::Initializers
end

