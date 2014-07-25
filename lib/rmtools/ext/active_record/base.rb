require_relative 'base/rand'
require_relative 'base/scope'
require_relative 'base/update'

module RMTools  
  module ActiveRecord
    module Base
      
      def self.extended(mod)
        mod.module_eval {
          include InstanceMethods # unnamed
          extend Rand # named...
          extend Scope
          extend Update
        }
      end
    
      module InstanceMethods
        
        def to_hash
          attributes
        end
        
        def resource_path
          "#{self.class.name.tableize}/#{id}"
        end
        
        # Find neighbors (and self)
        def with_same(*attrs)
          self.class.where(attrs.map_hash {|attr| [attr, self[attr]]})
        end
        
        # No neighbors?
        def uniq_by?(*attrs)
          same = with_same(*attrs)
          same = same.where('id != ?', id) if id
          same.empty?
        end
        
        # Use case:
        #   if update_attributes? attributes_hash
        #     @dependent_calculated_value = nil
        #   end
        # somewhere further:
        #   def dependent_calculated_value
        #     ifnull {calculate_dependent_value}
        #   end
        #
        # @ hash : attributes to update
        # @ force : whether to skip attributes protection check
        def update_attributes?(hash, force=false)
          if force
            hash.each {|k, v| self[k] = v}
          else
            self.attributes = hash
          end
          changed? && save
        end
        
      end
    end
  end
end
    
    
    