module Gcmd
end

Dir.glob(File.expand_path(File.dirname(__FILE__)+ "/gcmd/*.rb")).each do | classfile |
  require classfile
end