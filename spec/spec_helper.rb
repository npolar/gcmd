require "simplecov"
require "rspec"
require "faraday"

SimpleCov.start do
  add_filter "/spec/"
end
ENV.delete "GCMD_HTTP_PASSWORD"
ENV.delete "GCMD_HTTP_USERNAME"
ENV["GCMD_ENV"] = "test"

::Faraday.default_adapter = :test