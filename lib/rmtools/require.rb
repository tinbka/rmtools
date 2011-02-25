# encoding: utf-8
module RMTools
  # ` RMTools::require __FILE__, "*" ' requires all ruby files from dir named as file
  # ` RMTools::require "folder", "file" ' requires file.rb from dir `folder' in working directory
  # `RMTools::require "file" ' requires 'file.rb' from working directory
  def self.require(location, mask=nil)
    if !mask
      location, mask = File.dirname(__FILE__), location # /path/to/gems/rmtools
    end
    mask += '.rb' unless mask['.']
    location = File.expand_path(location).chomp('.rb')
    Dir.glob(File.join location, mask) {|file| Kernel.require file}
  end
end