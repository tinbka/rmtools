require 'set'
require 'scanf'
require 'strscan'
require 'active_support'
require 'rmtools.so'
require 'rmtools/version'
require 'rmtools/dependencies/extender'
  
module RMTools
  acronym!
  extend Extender
  
  class << self
    # Остановимся на том, чтобы включать здесь расширения
    # самого верхнего уровня, а остальные — в расширителях.
    # Тогда процесс расширения будет самодескриптивным
    # ровно настолько, наколько он может быть понятым
    # при текущей степени углубления в lib.
    def extend_active_record!(printerr=true)
      require 'active_record'
      #require 'openssl'
      extend! :ActiveRecord, by: :Connection
      extend! 'ActiveRecord::Base'
    rescue LoadError
      if printerr
        warn "Could not load ActiveRecord gem, ActiveRecord extension was not loaded"
      end
    end
    
    # putted closer so I can turn it off for compatibility testing
    def use_smarter_set_operations!
      require 'rmtools/ext/set'
      ::Array.__send__ :include, SmarterSetOperators
      ::Set.__send__ :include, SmarterSetOperators
    end
  end

  extend!      :Object, by: :Being
  include_in! :Object, :Compare
  
  use_smarter_set_operations!
  include_in! :Array, :Compare
  include_in! :Array, :FetchOpts
  include_in! :Array, :Helpers
  
  extend!      :String, by: :Concatenation
  include_in! :String, :Encoding
  include_in! :String, :Helpers
  include_in! :String, :IP
  include_in! :String, :Parsers
  include_in! :String, :Rand
  include_in! :String, :Reversed
  extend!      :String, by: :Russian
  include_in! :String, :Splitters
  
  extend_active_record! false
  
  
  sugar! :Object, by: :Initialization
  sugar! :Hash, by: :Dictation
  sugar! :Array, by: :Case
  sugar! :Array, by: :Iterators
end

