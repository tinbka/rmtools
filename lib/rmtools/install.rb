# encoding: utf-8
require File.expand_path('require', File.dirname(__FILE__))
RMTools::require 'fs'
require 'digest/md5'

def ext_files_not_modified(ext_name='rmtools', version='\d')
    return unless name = Gem.source_index.gems.keys.find {|n| 
      n =~ /^#{ext_name}-#{version}/
    }
    gemspec = Gem.source_index.gems[name]
    full_path  = gemspec.full_gem_path
    ext_files  = gemspec.files.grep(/^ext\//)
    ext_files.each {|f| 
      installed = File.join(full_path, f)
      return unless File.file? installed and Digest::SHA256.file(f) == Digest::SHA256.file(installed)
    }
end
  
def compile_manifest(exc=['pkg'])
    fs = Dir.new('.').recursive_content
    RMTools.rw 'Manifest.txt', (exc ? fs.reject {|i| i[/^(#{exc*'|'})\//]} : fs)*"\n"
end
