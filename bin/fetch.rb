#!/usr/bin/env ruby
require "bundler/setup"

require_relative "./../lib/gcmd"

c = Gcmd::Concepts.new
c.fetch_all
