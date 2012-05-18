# encoding: utf-8
require File.expand_path('require', File.dirname(__FILE__))
RMTools::require 'fs'

def ext_files_not_modified(ext_name, version)
  spec = Gem::Specification.find_all_by_name(ext_name).find {|s| s.version.version == version}
  return unless spec
  path = spec.full_gem_path
  !spec.files.grep(/^ext\//).find {|f|
    !(File.file?(installed=File.join(path, f)) and IO.read(f) == IO.read(installed))
  }
end
  
def compile_manifest(exc=%w(pkg))
  fs = Dir.new('.').recursive_content
  RMTools.rw 'Manifest.txt', (exc ? fs.reject {|i| i[/^(#{exc*'|'})\//]} : fs)*"\n"
end
