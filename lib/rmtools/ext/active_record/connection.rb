module RMTools
  module ActiveRecord
    module Connection
    
      def establish_connection_with(config='config/database.yml')
        c = case config
        when String
          c = if config.inline
            if c = RMTools.read(config) then c
            else return false
            end
          else config
          end
          YAML.load c
        when IO then YAML.load config
        else config
        end
        Base.establish_connection(c) rescue(false)
      end
      
    end
  end
end