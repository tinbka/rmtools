# encoding: utf-8
class Object
  # class Klass
  #   def old_method *argv
  #     deprecate_method :new_method, *argv
  #   end
  # end
  # Klass.new.old_method
  #   gives:
  # DEPRECATION from /path/to/libs/lib.rb: Klass#old_method is deprecated. Use #new_method instead.
  # => <new_method(*argv) result>
  #
  # Same shit:
  # class Klass
  #   deprecate_method :old_method, :new_method
  # end
  def deprecate_method message="", *argv
    caler = caller[0].parse(:caller)
    sym = nil
    if message.is Symbol
      sym, message = message, "Use ##{message} instead."
    end
    STDERR.puts "DEPRECATION from #{caler.path}: #{self.class}##{caler.func} is deprecated. #{message.capitalize}" if caler
    __send__ sym, *argv if sym
  end
  
end

class Class
  
  def deprecate_method old_method, new_method
    define_method(new_method) {|*argv| deprecate_method old_method, *argv}
  end
  
end