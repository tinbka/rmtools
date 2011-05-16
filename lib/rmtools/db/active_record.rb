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
      return attributes if respond_to? :attributes
      serializer = Serializer.new(self)
      serializer.respond_to?(:attributes_hash) ?
        serializer.attributes_hash : 
        serializer.serializable_record
    end
    
    alias :delete_with_id :delete
    alias :destroy_with_id :destroy
    # by default model.delete() and model.destroy() won't work if model has no id
    def delete(field=nil)
      id ? 
        delete_with_id : 
        field ? 
          self.class.delete_all(field => __send__(field)) : 
          self.class.delete_all(attributes)
    end
        
    def destroy(field=nil)
      id ? 
        destroy_with_id : 
        field ? 
          self.class.destroy_all(field => __send__(field)) : 
          self.class.destroy_all(attributes)
    end
    
    def self.merge_conditions(*conditions)
      segments = conditions.map {|condition| 
        sanitize_sql condition
      }.reject {|condition|
        condition.blank?
      }
      "(#{segments.join(') AND (')})" unless segments.empty?
    end
    
    def self.execute_sanitized(sql)
      connection.execute sanitize_sql sql
    end
    
    # requires primary key
    def self.forced_create(hash)
      names = columns.names
      id = (hash[primary_key.to_sym] ||= maximum(primary_key)+1)
      execute_sanitized([
        "INSERT INTO #{quoted_table_name} VALUES (:#{names*', :'})", 
        Hash[names.map {|name| [name.to_sym, nil]}].merge(hash)
      ])
      find_by_sql(["SELECT * FROM #{quoted_table_name} WHERE #{primary_key} = ?", id])[0]
    end
    
  end
    
end
    
    
    