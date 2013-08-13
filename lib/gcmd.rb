require "tmpdir"
module Gcmd
  if ENV.key? "GCMD_CACHE"
    CACHE = ENV["GCMD_CACHE"]
  else
    CACHE = Dir.tmpdir+"/gcmd-cache"
  end
end

require_relative "gcmd/exception"
require_relative "gcmd/dif"
require_relative "gcmd/tools"
require_relative "gcmd/http"
require_relative "gcmd/concepts"
require_relative "gcmd/dif_builder"
require_relative "gcmd/schema"
