module RMTools
  module ActiveRecord
    module Base
      module Rand
        
        # Written for MySQL, may not work on other DB
        # @ limit : int <total limit>
        # @ options :
        #   ids : int array <just select from these ids>
        #   fields : string array <select only these fields>
        #   cnt : int <in how many rows (first by table default order) to get records>
        #   { unless cnt } cnt_where : string <where-condition to get :cnt>
        #   { unless cnt } cnt_from : string <from-condition to get :cnt>
        #   discnt : int <decrement :cnt by this>
        #   where : string <where-condition>
        #   from : string <from-condition>
        # => array <selected records>
        def select_rand(limit=nil, options={})
          unless limit
            return select_rand(1)[0]
          end
          
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
          tables = options.delete(:from) || options.delete(:tables) || table_name
          cnt_tables = options.delete(:cnt_from) || options.delete(:cnt_tables) || tables
          fields = (options.delete(:fields) || %w[*])*','
          
          find_by_sql(["SELECT * FROM (
              SELECT @cnt:=#{cnt ? cnt.to_i : 'COUNT(*)'}+1#{-discnt.to_i if discnt}, @lim:=#{limit.to_i}#{" FROM #{cnt_tables} WHERE #{cnt_where}" if !cnt}
            ) vars
            STRAIGHT_JOIN (
              SELECT #{fields}, @lim:=@lim-1 FROM #{tables} WHERE #{"(#{_where}) AND " if _where} (@cnt:=@cnt-1) AND RAND() < @lim/@cnt
            ) i", options])
        end
        
      end
    end
  end
end