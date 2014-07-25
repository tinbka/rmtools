module RMTools
  module ActiveRecord
    module Base
      module Update
        
        def affected_rows_count(*column_names)
          "Updated #{connection.instance_variable_get(:@connection).affected_rows} #{column_names.map {|name| name.to_s.pluralize}*', '}"
        end
         
        # Usage:
        #
        # To update "officials.organisation_name"
        # by values of "organisations.short_title"
        # using "officials.organisation_uid" as foreign key
        # def Official.update_organisation_names!
        #   update_reference_columns! referred_class: Organisation,
        #     column_name: :organisation_name,
        #     foreign_column_name: :short_title,
        #     key: :organisation_uid
        # end
        #
        # By default column names infer from model names
        #
        # To use predefined 2-tuple array as reference table
        # update_reference_columns! columns_reference: [[1, "My first value"], [2, "My second value"]]
        #
        # To use another match operator
        # update_reference_columns! op: "in (?)",
        #   columns_reference: [[[1, 2, 3], "One of my first three values"], [[12, 13], "One of my last two values"]]
        def update_reference_columns!(referred_class: self, columns_reference: nil, reference_name: nil, column_name: nil, foreign_column_name: nil, key: nil, op: '= ?')
          # да, pluck не умеет выбирать туплы, по крайней мере в 3 версии
          columns_reference ||= referred_class.select([:id, foreign_column_name]).map {|obj| [obj.id,obj[foreign_column_name]]}
          reference_name ||= referred_class.name.underscore
          key ||= "#{reference_name}_id"
          column_name ||= "#{reference_name}_#{foreign_column_name}"
          execute_sanitized [
            "UPDATE #{quoted_table_name} 
            SET #{column_name} = CASE
            #{" WHEN #{key} #{op} THEN ?" * columns_reference.size} 
            ELSE #{column_name} END", 
            *columns_reference.flatten]
          puts affected_rows_count column_name
        end
        
        # Usage:
        #
        # To update "officials.actual_organisation_id"
        # by values of "organisations.id"
        # using "officials.my_organisation_id" as foreign key
        # def Official.update_organisation_ids!
        #   update_reference_ids! referred_class: Organisation,
        #     reference_name: 'actual_organisation', 
        #     ids_reference: organisation_ids_reference,
        #     key: my_organisation_id
        # end
        #
        # By default column names infer from model names
        #
        # To use predefined 2-tuple array as reference table
        # update_reference_ids! ids_reference: [[1, 5], [10, 20]]
        #
        # To use another match operator
        # update_reference_ids! op: "in (?)",
        #   ids_reference: [[[1, 2, 3], 5], [[12, 13], 20]]
        def update_reference_ids!(referred_class: self, ids_reference: nil, reference_name: nil, key: nil, op: '= ?')
          ids_reference ||= referred_class.select([:id, :uid]).map {|obj| [obj.uid,obj.id]}
          reference_name ||= referred_class.name.underscore
          key ||= "#{reference_name}_uid"
          update_reference_columns! columns_reference: ids_reference, reference_name: reference_name, foreign_column_name: :id, key: key, op: op
        end
     
      end
    end
  end
end