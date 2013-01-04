# encoding: utf-8
RMTools::require 'enumerable/array'

unless defined? RMTools::Iterators
  
  # [1, 2, 3].to_ss # => ['1', '2', '3']
  # [[1,2,3], [4,5,6], [7,8,9]].to_sss
  # => [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]]
  # [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"]].subss!(/\d+/) {|m| (m.to_i % 3).to_s}
  # => [["1", "2", "0"], ["1", "2", "0"], ["1", "2", "0"]]
  # [[1, 2, 0], [1, 2, 0], [1, 2, 0]].sum_zeros?
  # => [false, false, true, false, false, true, false, false, true]
  # [[1, 2, 3], [3, 4, 6], [3, 8, 0]].uniq_by_odds?
  # => [[1, 2, 3], [3, 4, 6]]
  class Array
    alias :throw_no :method_missing
    alias :arrange_by :arrange
    RMTools::Iterators = %r{^(#{(my_methods(/_by$/)+%w{every no select reject partition find_all find sum foldr})*'|'})_([\w\d\_]+[!?]?)}
    
    def method_missing(method, *args, &block)
      if match = (meth = method.to_s).match(RMTools::Iterators)
        iterator, meth = match[1].to_sym, match[2].to_sym
        begin
          case iterator
          when :every then iterator = :every?
          when :no     then iterator = :no?
          end
          return case iterator
            when :sum;     sum(args.shift) {|i| i.__send__ meth, *args, &block}
            when :find_by, :select_by, :reject_by; __send__(iterator, meth, *args)
            else __send__(iterator) {|i| i.__send__ meth, *args, &block}
            end
        rescue NoMethodError => e
          e.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
          raise e
        end
      elsif meth.sub!(/sses([=!?]?)$/, 'ss\1') or meth.sub!(/ies([=!?]?)$/, 'y\1') or meth.sub!(/s([=!?]?)$/, '\1')
        assignment = meth =~ /=$/
        meth = meth.to_sym
        begin 
          if assignment
            if Array === args
                each_with_index {|e,i| e.__send__ meth, args[i]}
            else
                each {|e| e.__send__ meth, args}
            end
          else map {|e| e.__send__ meth, *args, &block}
          end
        rescue NoMethodError => e
          e.message << " (`#{method}' interpreted as map-function `#{meth}')"
          raise e
        end
      else throw_no method
      end      
    end
  end

end