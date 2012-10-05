#!/usr/bin/env ruby
require "bundler/setup"
require "yajl/json_gem"
require_relative "./../lib/gcmd"

docs = []
Gcmd::Concepts.schemas.each do |schema|

  c = Gcmd::Concepts.new
  collection = c.triples(schema).map {|id, title, summary|
    {:_id=>id, :title => title, :summary=> summary, :collection => schema, :workspace => "gcmd", :version => Gcmd::Concepts::VERSION }}
  collection.each do | doc |
    docs << doc
  end
end
puts docs.to_json
