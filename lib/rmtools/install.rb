# encoding: utf-8
require File.expand_path('require', File.dirname(__FILE__))
RMTools::require 'fs'
require 'digest/md5'

def ext_files_not_modified(ext_name='rmtools', version='\d')
    gem = Gem.source_index.select {|a| a[0] =~ /^#{ext_name}-#{version}$/}[0]
    return unless gem
    gemspec = gem[1]
    path = gemspec.full_gem_path
    !gemspec.files.grep(/^ext\//).find {|f|
      !(File.file?(installed=File.join(path, f)) and IO.read(f) == IO.read(installed))
    }
end
  
def compile_manifest(exc=%w(pkg))
    fs = Dir.new('.').recursive_content
    RMTools.rw 'Manifest.txt', (exc ? fs.reject {|i| i[/^(#{exc*'|'})\//]} : fs)*"\n"
end
