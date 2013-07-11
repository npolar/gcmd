module Gcmd
  CACHE = ENV["GCMD_CACHE"] ||= ENV["HOME"] + "/.gcmd"
end

require_relative "gcmd/exception"
require_relative "gcmd/dif"
require_relative "gcmd/tools"
require_relative "gcmd/http"
require_relative "gcmd/concepts"
require_relative "gcmd/dif_builder"
require_relative "gcmd/schema"