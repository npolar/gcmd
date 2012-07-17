require "simplecov"
require "rspec"
require "faraday"

SimpleCov.start

ENV.delete "GCMD_HTTP_PASSWORD"
ENV.delete "GCMD_HTTP_USERNAME"

::Faraday.default_adapter = :test