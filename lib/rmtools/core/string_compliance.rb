# encoding: utf-8
# Problem with subs is solved, so now here will be only #ord
if RUBY_VERSION < "1.9"
  class String
    def ord; self[0] end
  end
end