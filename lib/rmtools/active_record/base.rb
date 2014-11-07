# encoding: utf-8
module ActiveRecord
  
  class << self
    
    def establish_connection_with config='config/database.yml'
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
      if defined? Rails
        env = Rails.env.to_s
        if c.include? env
          c = c[env]
        end
      end
      Base.establish_connection(c) rescue(false)
    end
      
    alias establish_connection establish_connection_with
    
  end

  class Base
    class_attribute :enums
    
    class << self
    
      def establish_connection_with config
        ActiveRecord.establish_connection_with config
      end
      
      def merge_conditions(*conditions)
        segments = conditions.map {|condition| 
          sanitize_sql condition
        }.reject {|condition|
          condition.blank?
        }
        "(#{segments.join(') AND (')})" unless segments.empty?
      end
      
      def execute_sanitized(sql)
        connection.execute sanitize_sql sql
      end
      
      # requires primary key
      def forced_create(hash)
        names = columns.names
        id = (hash[primary_key.to_sym] ||= maximum(primary_key)+1)
        execute_sanitized([
          "INSERT INTO #{quoted_table_name} VALUES (:#{names*', :'})", 
          Hash[names.map {|name| [name.to_sym, nil]}].merge(hash)
        ])
        find_by_sql(["SELECT * FROM #{quoted_table_name} WHERE #{primary_key} = ?", id])[0]
      end
      
      # values must be 2-tuple array [[column1, value1], [column2, value2], ...] and columns must be in order they've been created
      def insert_unless_exist(table, values)
        table = connection.quote_table_name table
        if execute_sanitized(["SELECT COUNT(*) FROM #{table} WHERE #{vaues.firsts.map {|v| "#{connection.quote_column_name v}=?"}*' AND '} LIMIT 1", *values.lasts]).to_a.flatten > 0
          false
        else
          execute_sanitized ["INSERT INTO #{table} VALUES (#{['?']*values.size*','})", *values.lasts]
          true
        end
      end
      
      def select_rand(limit, options={})
        cnt = options.delete :cnt
        _where = options.delete :where
        cnt_where = options.delete(:cnt_where) || _where
        if !cnt and !cnt_where
          ids = options[:ids] || pluck(:id)
          if fields = options[:fields]
            return select(fields).where(id: ids.randsample(limit)).all
          else
            return where(id: ids.randsample(limit)).all
          end
          #cnt = options[:ids].size
          #where ||= "#{table_name}.id IN (:ids)"
        end
        discnt = options.delete :discnt
        tables = options.delete(:tables) || table_name
        cnt_tables = options.delete(:cnt_tables) || tables
        fields = (options.delete(:fields) || %w[*])*','
        
        find_by_sql(["SELECT * FROM (
            SELECT @cnt:=#{cnt ? cnt.to_i : 'COUNT(*)'}+1#{-discnt.to_i if discnt}, @lim:=#{limit.to_i}#{" FROM #{cnt_tables} WHERE #{cnt_where}" if !cnt}
          ) vars
          STRAIGHT_JOIN (
            SELECT #{fields}, @lim:=@lim-1 FROM #{tables} WHERE #{"(#{_where}) AND " if _where} (@cnt:=@cnt-1) AND RAND() < @lim/@cnt
          ) i", options])
      end
        
      # virtual (only-in-ruby) "enum" type support
      def enum hash
        key = hash.keys.first
        (self.enums ||= {}).merge! hash
        define_attribute_methods if !attribute_methods_generated?
        class_eval %{
        def #{key}
          missing_attribute('#{key}', caller) unless @attributes.has_key?('#{key}')
          self.class.enums[:#{key}][@attributes['#{key}']]
        end
        def #{key}=(val)
         write_attribute('#{key}', Fixnum === val ? val : self.class.enums[:#{key}].index val.to_s
        end
       }
      end
     
      # usable to define shortcut-scopes on class with number of boolean flags: #admin, #open, #removed, etc
      def boolean_scopes!
        columns.select_by_type(:boolean).names.to_syms.each {|col|
          unless respond_to? col
            scope col, where("#{quoted_table_name}.#{col} = 1")
          end
        }
        rescue
        nil
      end
     
      # more universal version of boolean_scopes! that helps to find records with any non-null values,
      # including zero and empty string
      def non_null_scopes!
        boolean_scopes!
        columns.select_null.names.to_syms.each {|col|
          unless respond_to? col
            scope col, where("#{quoted_table_name}.#{col} is not null")
          end
        }
      rescue
        nil
      end
   
    end
   
    # fix for thinking_sphinx equation in #instances_from_class:
    # ids.collect {|obj_id| instances.detect do |obj| obj.primary_key_for_sphinx == obj_id end}
    # where obj_id is Array
    #def primary_key_for_sphinx
    #  [read_attribute(self.class.primary_key_for_sphinx)]
    #end
    
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
          self.class.delete_all(field => self[field]) : 
          self.class.delete_all(attributes)
    end
        
    def destroy(field=nil)
      id ? 
        destroy_with_id : 
        field ? 
          self.class.destroy_all(field => self[field]) : 
          self.class.destroy_all(attributes)
    end
    
    def resource_path
      "#{self.class.name.tableize}/#{id}"
    end
    
    def with_same(attr)
      self.class.where(attr => self[attr])
    end
  
    def update_attributes?(hash)
      hash.each {|k, v| self[k] = v}
      changed? && save
    end
    
  end
  
  class Relation
    
    def any?
      limit(1).count != 0
    end
    
    def empty?
      limit(1).count == 0
    end
    
  end
    
end
    
    
    