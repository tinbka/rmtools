# encoding: utf-8
Dir.chdir(File.expand_path File.dirname __FILE__) {require 'io'; require 'boolean'}
require 'digest/md5'

def ext_files_not_modified(ext_name='rmtools')
    return unless name = Gem.source_index.gems.keys.find {|n| 
      n =~ /^#{ext_name}-\d/
    }
    gemspec = Gem.source_index.gems[name]
    full_path  = gemspec.full_gem_path
    ext_files  = gemspec.files.grep(/^ext\//)
    ext_files.each {|f| 
      insalled = File.join(full_path, f)
      return unless File.file? insalled and Digest::SHA256.file(f) == Digest::SHA256.file(insalled)
    }
end
  
def compile_manifest(exc=['pkg'])
    fs = Dir.new('.').recursive_content
    RMTools.rw 'Manifest.txt', (exc ? fs.reject {|i| i[/^(#{exc*'|'})\//]} : fs)*"\n"
end
