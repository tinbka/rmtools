# encoding: utf-8
module RMTools
  # ` RMTools::require __FILE__, "*" ' requires all ruby files from dir named as file under 'rmtools-gem/lib/rmtools'
  # ` RMTools::require "folder", "mask" ' requires all files come within `mask' from dir `folder' under 'rmtools-gem/lib/rmtools'
  # `RMTools::require "file" ' requires 'file.rb' under 'rmtools-gem/lib/rmtools'
  def self.require(location, mask=nil)
    if !mask
      location, mask = File.dirname(__FILE__), location # /path/to/gems/rmtools
    end
    mask += '.rb' unless mask['.']
    location = File.expand_path(location).chomp('.rb')
    Dir.glob(File.join location, mask) {|file| Kernel.require file}
  end
end