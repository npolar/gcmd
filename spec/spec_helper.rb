require "simplecov"
require "rspec"
require "faraday"
require "gcmd"

SimpleCov.start do
  add_filter "/spec/"
end
ENV.delete "GCMD_HTTP_PASSWORD"
ENV.delete "GCMD_HTTP_USERNAME"

# Flag test enviroment with ENV["GCMD_ENV"] = "test" to disable logging
ENV["GCMD_ENV"] = "test"

::Faraday.default_adapter = :test
