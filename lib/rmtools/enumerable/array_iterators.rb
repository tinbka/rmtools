# encoding: utf-8
RMTools::require 'enumerable/array'

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
  mattr_reader :iterators_names, :iterators_pattern
  @@iterators_names = []
  
  class << self
    
    def add_iterator_name(name_or_list)
      name_or_list = [name_or_list] if !name_or_list.is Array
      @@iterators_names |= name_or_list
      @@iterators_pattern = %r{^(#{@@iterators_names*'|'})_([\w\d\_]+[!?]?)}
    end
  
    def fallback_to_clean_iterators!
      class_eval do
        # Benchmark 1:
        # # We take a simple methods like uniq_by (O(N)) and odd? (O(1)) to ensure that
        # # penalty we would have in production would not be larger than that in bench
        #
        # # 1.1. Traditional calls:
        # # 1.1.1: (9 x #odd? + 3 x #map + 1 x #uniq_by) * 10^6
        # timer(1_000_000) { [[1, 2, 3], [3, 4, 6], [3, 8, 0]].uniq_by {|i| i.map {|j| j.odd?}} }
        # one: 0.0130ms, total: 13040.0ms
        # # 1.1.2: (90_000 x #odd? + 300 x #map + 1 x #uniq_by) * 100
        # timer(100) { a.uniq_by {|i| i.map {|j| j.odd?}} }
        # one: 34.0000ms, total: 3400.0ms
        #
        # # 1.2. Meta calls:
        # # 1.2.1: += (13 * 10^6 x #__send__) + (4 * 10^6 x #method_missing)
        # timer(1_000_000) { [[1, 2, 3], [3, 4, 6], [3, 8, 0]].uniq_by_odds? }
        # one: 0.0354ms, total: 35440.0ms 
        # # += 172% of time
        # a = (0...300).to_a.map {Array.rand 300};
        # # 1.2.2: += (9 * 10^6 x #__send__) + (30_100 x #method_missing)
        # timer(100) { a.uniq_by_odds? }
        # one: 39.3000ms, total: 3930.0ms
        # # += 16% of time
        #
        # Conclusion:
        # 
        # 1. If we want to speed meta-calls up, we should sacrifice cleanness of Array namespace,
        # I mean define missing methods inplace.
        # 2. Most latency is given by #method_missing, but which are factor of #__send__?
        def method_missing(method, *args, &block)
          if match = (meth = method.to_s).match(@@iterators_pattern)
            iterator, meth = match[1].to_sym, match[2].to_sym
            
            begin
              case iterator
              when :every then iterator = :every?
              when :no     then iterator = :no?
              end
              
              return case iterator
                when :sum, :sort_along_by; __send__(iterator, args.shift) {|i| i.__send__ meth, *args, &block}
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
            
          else 
            throw_no method
          end      
        end
      end # class_eval
    end # def fallback_to_clean_iterators!
  
  end # << self
    
  add_iterator_name(instance_methods.grep(/_by$/)+%w{every no select reject partition find_all sum foldr foldl fold count rand_by})

  # Benchmark 2:
  #
  # # 2.2. Meta calls:
  # # 2.2.1: += (13 * 10^6 x #__send__)
  # timer(1_000_000) { [[1, 2, 3], [3, 4, 6], [3, 8, 0]].uniq_by_odds? }
  # one: 0.0156ms, total: 15570.0ms
  # # += 19% of time
  # a = (0...300).to_a.map {Array.rand 300};
  # # 2.2.2: += (9 * 10^6 x #__send__)
  # timer(100) { a.uniq_by_odds? }
  # one: 37.9000ms, total: 3790.0ms
  # # += 11% of time
  <<-'version 2'
  def method_missing(method, *args, &block)
    if match = (meth = method.to_s).match(@@iterators_pattern)
      iterator, meth = match[1].to_sym, match[2].to_sym
      case iterator
      when :every then iterator = :every?
      when :no     then iterator = :no?
      end
      
      Array.class_eval do
        case iterator
        when :sum, :sort_along_by
          define_method method do |*args, &block|
            begin
              # sum_posts_ids([], :all)  =>  
              # sum([]) {|e| e.posts_ids(:all)}
              __send__(iterator, args.shift) {|i| e.__send__ meth, *args, &block}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end
          end
        when :find_by, :select_by, :reject_by
          define_method method do |*args, &block|
            begin
              # select_by_count(max_count)  =>  
              # select {|e| e.count == max_count}
              __send__(iterator, meth, *args)
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end
          end
        else 
          define_method method do |*args, &block|
            begin
              # uniq_by_sum(1) {|i| 1 / i.weight}  =>  
              # uniq_by {|e| e.sum(1) {|i| 1 / i .weight}}
              __send__(iterator) {|e| e.__send__ meth, *args, &block}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end
          end
        end
      end
      
    elsif meth.sub!(/sses([=!?]?)$/, 'ss\1') or meth.sub!(/ies([=!?]?)$/, 'y\1') or meth.sub!(/s([=!?]?)$/, '\1')
      assignment = meth =~ /=$/
      meth = meth.to_sym
      
      Array.class_eval do
        if assignment
          define_method method do |value|
            begin
              if Array === value
                # owner_ids = users_ids  =>  
                # each_with_index {|e, i| e.owner_id = users_ids[i]}
                each_with_index {|e, i| e.__send__ meth, value[i]}
              else
                # owner_ids = user_id  =>  
                # each {|e, i| e.owner_id = user_id}
                each {|e| e.__send__ meth, value}
              end
            rescue NoMethodError => e
              e.message << " (`#{method}' interpreted as map-function `#{meth}')"
              raise e
            end
          end
        else
          define_method method do |*args, &block|
            begin
              # to_is(16)  =>  
              # map {|e| e.to_i(16)}
              map {|e| e.__send__ meth, *args, &block}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as map-function `#{meth}')"
              raise err
            end
          end
        end
      end
      
    else 
      return throw_no method
    end      
      
    __send__(method, *args, &block)
  end
  version 2
  
  # Benchmark 3:
  #
  # # 3.2. Meta calls:
  # # 3.2.1: += (13 * 10^6 x #__send__)
  # timer(1_000_000) { [[1, 2, 3], [3, 4, 6], [3, 8, 0]].uniq_by_odds? }
  # one: 0.0145ms, total: 14520.0ms
  # # += 11% of time
  # a = (0...300).to_a.map {Array.rand 300};
  # # 3.2.2: += (9 * 10^6 x #__send__)
  # timer(100) { a.uniq_by_odds? }
  # one: 36.1000ms, total: 3610.0ms
  # # += 6% of time
  def method_missing(method, *args, &block)
    if match = (meth = method.to_s).match(@@iterators_pattern)
      iterator, meth = match[1].to_sym, match[2].to_sym
      case iterator
      when :every then iterator = :every?
      when :no     then iterator = :no?
      end
      
      case iterator
      when :sum, :sort_along_by
        Array.class_eval %{
      def #{method}(*args, &block)
        # sum_posts_ids([], :all) =>
        # sum([]) {|e| e.posts_ids(:all)}
        #{iterator}(args.shift) {|e| e.#{meth}(*args, &block)}
      rescue NoMethodError => err
        err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
        raise err
      end}
      when :find_by, :rfind_by,:select_by, :reject_by
        Array.class_eval %{
      def #{method}(val)
        # select_by_count(max_count) =>
        # select {|e| e.count == max_count}
        #{iterator.to_s[0...-3]} {|e| e.#{meth} == val}
      rescue NoMethodError => err
        err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
        raise err
      end}
      else
        Array.class_eval %{
      def #{method}(*args, &block)
        # uniq_by_sum(1) {|i| 1 / i.weight}  =>  
        # uniq_by {|e| e.sum(1) {|i| 1 / i .weight}}
        #{iterator} {|e| e.#{meth}(*args, &block)}
      rescue NoMethodError => err
        err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
        raise err
      end}
      end
      
    elsif meth.sub!(/sses([=!?]?)$/, 'ss\1') or meth.sub!(/ies([=!?]?)$/, 'y\1') or meth.sub!(/s([=!?]?)$/, '\1')
      assignment = meth =~ /=$/
      meth = meth.to_sym
      
      if assignment
        Array.class_eval %{
      def #{method}(value)
        if Array === value
          # owner_ids = users_ids  =>  
          # each_with_index {|e, i| e.owner_id = users_ids[i]}
          each_with_index {|e, i| e.#{meth} value[i]}
        else
          # owner_ids = user_id  =>  
          # each {|e, i| e.owner_id = user_id}
          each {|e| e.#{meth} value}
        end
      rescue NoMethodError => err
        err.message << " (`#{method}' interpreted as map-function `#{meth}')"
        raise err
      end}
      else
        Array.class_eval %{
      def #{method}(*args, &block)
        # to_is(16)  =>  
        # map {|e| e.to_i(16)}
        map {|e| e.#{meth}(*args, &block)}
      rescue NoMethodError => err
        err.message << " (`#{method}' interpreted as map-function `#{meth}')"
        raise err
      end}
      end
      
    else 
      return throw_no method
    end      
      
    __send__(method, *args, &block)
  end
  
end