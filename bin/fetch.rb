#!/usr/bin/env ruby
require "bundler/setup"

require "./../lib/gcmd/exception"
require "./../lib/gcmd/http"
require "./../lib/gcmd/concepts"

c = Gcmd::Concepts.new
c.fetch_all
