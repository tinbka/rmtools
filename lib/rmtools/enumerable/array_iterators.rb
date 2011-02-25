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
    RMTools::Iterators = %r{(#{(%w{select reject partition find_all find sum foldr min max}+instance_methods.grep(/_by$/))*'|'})_([\w\d\_]+[!?]?)}
    
    def method_missing(method, *args, &block)
      if match = (meth = method.to_s).match(RMTools::Iterators)
        iterator, meth = match[1..2]
        meth = meth.to_sym
        return send(iterator) {|i| i.__send__ meth, *args, &block}
      elsif meth.sub!(/sses([!?]?)$/, 'ss\1') or meth.sub!(/ies([!?]?)$/, 'y\1') or meth.sub!(/s([!?]?)$/, '\1')
        return map {|i| i.__send__ meth.to_sym, *args, &block}
      else
        throw_no method
      end
    rescue NoMethodError
      throw_no method
    end
  end

end