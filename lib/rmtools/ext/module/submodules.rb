module RMTools
  module Module
    module Submodules
  
      def children
        constants.map! {|name|
          begin
            const_get name
          rescue Exception
            puts "#{name} can not be loaded due to #{$!.class}: #{$!.message}"
          end
        }.uniq.compact.select {|_|
          _.is_a? Module and _ != self and _.name =~ /^#{self.name}::/ and
          block_given? ? yield(_) : true
        }
      end
      alias submodules children
      
      def descendants_tree
        children.map! {|_|
          if desc = _.descendants_tree.b
            [_, desc]
          else
            _
          end
        }
      end
      alias submodules_tree descendants_tree
                    
      def each_child(&b)
        children.each {|_| &b[_]; true}
      end
      alias each_submodule each_child
      
    end
  end
end