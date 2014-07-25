module RMTools
  module ActiveRecord
    module Base
      module Scope
   
        # usable to define shortcut-scopes on class with number of boolean flags: #admin, #open, #removed, etc
        def boolean_scopes!
          columns.select_by_type(:boolean).names.to_syms.each {|col|
            unless respond_to? col
              scope col, where("#{table_name}.#{col} = 1")
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
              scope col, where("#{table_name}.#{col} is not null")
            end
          }
        rescue
          nil
        end
        
      end
    end
  end
end