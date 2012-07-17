# encoding: utf-8
require File.dirname(__FILE__) + "/../spec_helper"
require "gcmd/http"
# Thanks to https://github.com/intridea/oauth2/blob/master/spec/oauth2/client_spec.rb

ENV.delete "GCMD_HTTP_PASSWORD"
ENV.delete "GCMD_HTTP_USERNAME"

Faraday.default_adapter = :test

describe Gcmd::Http do

  subject do
    http = Gcmd::Http.new(Gcmd::Http::BASE) do |builder|
      builder.adapter :test do |stub|
        stub.get("/401")    {|env| [401, {"Content-Type" => "text/html"}, "401"]}
        stub.get("/rdf")    {|env| [200, {"Content-Type" => "application/rdf+xml"}, '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:skos="http://www.w3.org/2004/02/skos/core#"></rdf:RDF>']}
        stub.get("/etag")   {|env| [200, {"Content-Type" => "text/plain", "ETag" => '"etag"'}, "500"]}
        stub.get('/500')  {|env| [500, {"Content-Type" => "text/plain"}, "500"]}
      end
    end
    http.username = "bingo"
    http.password = "bango"
    http

  end

  context "#initialize" do
    it "with a block configures the Faraday::Connection" do
      connection = stub('connection')
      session = stub('session', :to_ary => nil)
      builder = stub('builder')
      connection.stub(:build).and_yield(builder)
      Faraday::Connection.stub(:new => connection)

      builder.should_receive(:adapter).with(:test)

      Gcmd::Http.new do |builder|
        builder.adapter :test
      end.connection # RSpec::Mocks::Mock

    end
  end

  context "#get" do
    it "returns body as string" do
      subject.get("/rdf").should =~ /<rdf:RDF/
      subject.response.status.should == 200
      subject.response.headers["Content-Type"].should == "application/rdf+xml"
    end

    it "stores a Faraday::Response" do
      response = subject.get("/rdf")
      subject.response.class.should == Faraday::Response
    end

    it "appends paths to base URI" do
      # seems to work only if base URI is host
      response = subject.get("/rdf")
      subject.response.to_hash[:url].to_s.should == Gcmd::Http::BASE+"/rdf"
    end

    it "ignores base if path starts with http(s)" do
      response = subject.get("https://example.com/rdf")
      subject.response.to_hash[:url].to_s.should == ("https://example.com/rdf")
    end

    it "sends Basic Authorization" do
      response = subject.get("/rdf")
      subject.response.to_hash[:request_headers].should == {"Authorization"=>"Basic YmluZ286YmFuZ28="}
    end

    it "should send If-None-Match"
    # see https://github.com/mislav/faraday-stack/blob/master/test/caching_test.rb

    it "raises Exception on blank username or password" do
      subject.username = nil
      subject.password = nil
      expect { subject.get("/") }.to raise_error(Gcmd::Exception)    
    end

    it "raises Exception if status is not 200 or 304" do
      expect { subject.get("/500") }.to raise_error(Gcmd::Exception)    
    end
  end

  context "Misc" do
    context "#host" do
      it "should return the host" do
        subject.host.should == "gcmdservices.gsfc.nasa.gov"
      end

    end
  end
 
  context "#connection" do
    it "should return a Faraday::Connection instance" do
      http = Gcmd::Http.new
      http.connection.class.should == Faraday::Connection
    end
  end

  #context "REAL" do
  #  it "should work" do
  #    Faraday.default_adapter = :net_http
  #    http = Gcmd::Http.new
  #    response = http.get("/kms/concepts/root")
  #    response.should == ""
  #  end
  #end

end