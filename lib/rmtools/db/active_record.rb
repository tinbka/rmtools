# encoding: utf-8
require 'active_record'

module ActiveRecord

  def self.establish_connection_with config
    c = case config
            when String
              c = if config.inline
                      if c = RMTools.read(config) then c
                      else return; nil
                      end
                    else config
                    end
              YAML.load c
            when IO then YAML.load config
            else config
          end
    Base.establish_connection(c) rescue(false)
  end

  class Base
    
    def self.establish_connection_with config
      ActiveRecord.establish_connection_with config
    end
    
    def to_hash
      serializer = Serializer.new(self)
      serializer.respond_to?(:attributes_hash) ?
        serializer.attributes_hash : 
        serializer.serializable_record
    end
    
    alias :delete_with_id :delete
    # a problem was: model.delete() won't work if it has no id. Just delete() it if has
    def delete
      id ? delete_with_id : self.class.delete_all(attributes)
    end
    
    def self.merge_conditions(*conditions)
      segments = conditions.map {|condition| 
        sanitize_sql condition
      }.reject {|condition|
        condition.blank?
      }
      "(#{segments.join(') AND (')})" unless segments.empty?
    end
    
  end
    
end
    
    
    