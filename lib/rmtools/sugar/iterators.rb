module RMTools
  module Sugar
    module Iterators
    
      def self.extended(ary)
        ary.class_eval {
          extend ClassMethods
          
          cattr_reader :iterators_names, :iterators_pattern, instance_accessor: false
          self.iterators_names = []
          add_iterator_name instance_methods.grep(/_by$/)
          add_iterator_name  %w{every any no none which select reject partition find_all find sum foldr foldl fold count rand_by}
          
          def method_missing(method, *args, &block)
            if Array.define_iterator method
              __send__(method, *args, &block)
            else
              super
            end
          end
        }
      end
      
      module ClassMethods

        # It's here just because it's simplier and faster (40 times)
        # than ActiveSupport's singularization.
        # If you want to use latter one, run
        # Array.use_active_support_singularize!
        def simple_inplace_singularize!(noun)
          noun.sub!(/(ss|[sc]h|[xo])es([=!?]?)$/, '\1\2') or 
          noun.sub!(/ies([=!?]?)$/, 'y\1') or 
          noun.sub!(/s([=!?]?)$/, '\1')
        end
        
        def add_iterator_name(name_or_list)
          @@iterators_names |= Array name_or_list
          @@iterators_pattern = %r{^(#{@@iterators_names*'|'})_([\w\d\_]+[!?]?)}
        end
        
        def use_active_support_singularize!
          class_eval do
            def simple_inplace_singularize!(noun)
              ActiveSupport::Inflector.singularize noun
            end
          end
        end
      
        # It's third implementation of meta-iterator.
        # Other two are available in 2.x versions of rmtools
        #
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
        def define_iterator(method)
          if match = (meth = method.to_s).match(iterators_pattern)
            iterator, meth = match[1], match[2]
            iterator.sub!(/^((?:ever|an)y|no(?:ne)?)$/, '\1?')
            iterator = iterator.to_sym
            
            case iterator
            when :sum, :sort_along_by
              # sum_posts_ids([], :all) =>
              # sum([]) {|e| e.posts_ids(:all)}
              class_eval %{
            def #{method}(*args, &block)
              #{iterator}(args.shift) {|e| e.#{meth}(*args, &block)}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end}
            when :find_by, :rfind_by, :select_by, :reject_by, :partition_by
              # select_by_count(max_count) =>
              # select {|e| e.count == max_count}
              class_eval %{
            def #{method}(val)
              #{iterator.to_s[0...-3]} {|e| e.#{meth} == val}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end}      
            when :fold, :foldl, :foldr
              # fold_responders(:|, []) =>
              # fold(:|, []) {|e| e.responders}
              class_eval %{
            def #{method}(*args, &block)
              #{iterator}(*args[0, 2]) {|e| e.#{meth}(*args[2..-1], &block)}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end}
            else
              # uniq_by_sum(1) {|i| 1 / i.weight}  =>  
              # uniq_by {|e| e.sum(1) {|i| 1 / i .weight}}
              class_eval %{
            def #{method}(*args, &block)
              #{iterator} {|e| e.#{meth}(*args, &block)}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as decorator-function `#{meth}')"
              raise err
            end}
            end
            
          elsif simple_inplace_singularize!(meth)
            assignment = meth =~ /=$/
            meth = meth.to_sym
            
            if assignment
              # if Array === value
              #   owner_ids = users_ids  =>  
              #   each_with_index {|e, i| e.owner_id = users_ids[i]}
              # else
              #   owner_ids = user_id  =>  
              #   each {|e, i| e.owner_id = user_id}
              class_eval %{
            def #{method}(value)
              if Array === value
                each_with_index {|e, i| e.#{meth} value[i]}
              else
                each {|e| e.#{meth} value}
              end
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as map-function `#{meth}')"
              raise err
            end}
            else
              # to_is(16)  =>  
              # map {|e| e.to_i(16)}
              class_eval %{
            def #{method}(*args, &block)
              map {|e| e.#{meth}(*args, &block)}
            rescue NoMethodError => err
              err.message << " (`#{method}' interpreted as map-function `#{meth}')"
              raise err
            end}
            end
            
            true
          else
            false
          end
        end
        
      end
      
    end
  end
end