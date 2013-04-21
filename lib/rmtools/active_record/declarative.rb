# encoding: utf-8
module ActiveRecord

  module ConnectionAdapters
    AbstractAdapter
  
    class VirtualTable < Table
      
      def debug_str meth, called, exist, *args
        "Table.#{meth}(#{args.inspects*', '}) was#{' NOT' if !called} called due to #{'in' if !exist}existance"
      end
      
      def column_exists *args
        column_names = @base.columns(@table_name).names
        options = args.extract_options!
        names = args.dup
        args << options
        _or_ = (names[0] == :all) ? !names.shift : true
        names.each {|name| return _or_ if name.to_s.in(column_names) == _or_}
        !_or_
      end
      
      def index_exists *indexes
        column_indexes = @base.indexes(@table_name).columnss.flatten
        _or_ = (indexes[0] == :all) ? !indexes.shift : true
        indexes.each {|index| return _or_ if index.to_s.in(column_indexes) == _or_}
        !_or_
      end
      
      def initialize name, connection, map=nil
        super name, connection
        case map
          when true; @map = []
          when Array; @map = map
        end
      end
      
      def map!
        map_names = @map.firsts.to_ss
        @base.columns(@table_name).names.each {|name|
          name.in(map_names) ? @map.reject! {|_| _[0] == name} : remove(name)
        }
        @map.each {|col| column *col}
      end
      
      def column name, *args
        to_be_called = !column_exists(name)
        super if to_be_called
        $log.debug {debug_str :column, to_be_called,  !to_be_called, name, *args}
        @map << [name, *args] if @map
      end
        
      %w{string text integer float decimal
  datetime timestamp time date binary boolean}.each {|column_type| 
          define_method(column_type) {|*args|
            to_be_called = !column_exists(*args)
            super if to_be_called
            $log.debug {debug_str column_type, to_be_called,  !to_be_called, *args}
            if @map
              options = args.extract_options!
              args = args.xprod(column_type)
              args = args.xprod(options) if options
              @map.concat args
            end
      } }
      
      def index name, *args
        to_be_called = !index_exists(name)
        super if to_be_called
        $log.debug {debug_str :index, to_be_called, !to_be_called, name, *args}
      end
      
      def timestamps
        to_be_called = !column_exists('created_at', 'updated_at')
        super if to_be_called
        $log.debug {debug_str :timestamps, to_be_called, !to_be_called}
        @map.concat [[:created_at, :datetime], [:updated_at, :datetime]] if @map
      end
      
      def change *args
        raise NotImplementedError, "don't use #change in declaration!"
      end
      
      def change_default *args
        raise NotImplementedError, "don't use #change_default in declaration!"
      end
      
      def rename column_name, new_column_name
        to_be_called = !column_exists(new_column_name)
        super if to_be_called
        $log.debug {debug_str :rename, to_be_called, !to_be_called, column_name, new_column_name}
      end
      
      def references *args
        to_be_called = !column_exists(*args.map {|col| "#{col}_id"})
        super if to_be_called
        $log.debug {debug_str :references, to_be_called,  !to_be_called, *args}
      end
      alias :belongs_to :references
      
      def remove *args
        to_be_called = column_exists :all, *args
        super if to_be_called
        $log.debug {debug_str :remove, to_be_called, to_be_called, *args}
      end
      
      def remove_references *args
        to_be_called = column_exists(:all, *args.map {|col| "#{col}_id"})
        super if to_be_called
        $log.debug {debug_str :remove_references, to_be_called, to_be_called, *args}
      end
      alias :remove_belongs_to :remove_references
      
      def remove_index options
        indexes = options.is(Hash) ? options[:column] : options
        raise ArgumentError, "can remove only default format named indexes in declaration!" if !indexes
        to_be_called = index_exists :all, *indexes
        super if to_be_called
        $log.debug {debug_str :remove_index, to_be_called,  to_be_called, options}
      end
      
      def remove_timestamps
        to_be_called = column_exists 'created_at', 'updated_at'
        super if to_be_called
        $log.debug {debug_str :remove_timestamps, to_be_called, to_be_called}
      end
      
    end
      
  end

  class << Base
    
    def declare(name, options={}, &block)
      self.table_name = name
      if !table_exists? or options[:force]
        $log < "with options[:force] the `#{table_name}` table will have been recreated each time you load the #{model_name} model" if options[:force]
        self.primary_key = options[:primary_key] if options[:id] != false and options[:primary_key]
        $log.debug "connection.create_table(#{name}, #{options.inspect}) {}"
        connection.create_table(name, options, &block)
      elsif options[:map]
        table = ConnectionAdapters::VirtualTable.new(name, connection, options[:map])
        yield table
        table.map!
      else yield ConnectionAdapters::VirtualTable.new(name, connection)
      end
      reset_column_information
    end
    
  end
    
end
    