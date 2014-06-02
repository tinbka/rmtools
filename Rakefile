require "bundler/gem_tasks"

if RUBY_VERSION < '2'
  task :default => [:compile, :test]
else
  task :default => [:test]
end