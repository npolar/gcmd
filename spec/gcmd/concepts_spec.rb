# encoding: utf-8
require File.dirname(__FILE__) + "/../spec_helper"
require "gcmd/exception"
require "gcmd/http"
require "gcmd/concepts"

ENV.delete "GCMD_HTTP_PASSWORD"
ENV.delete "GCMD_HTTP_USERNAME"
Faraday.default_adapter = :test

describe Gcmd::Concepts do
  subject do
    Gcmd::Concepts.new  
  end
  
  LAST_PROJECT = "ZA ANTARCTIQUE"

  CONCEPT1 = '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:skos="http://www.w3.org/2004/02/skos/core#"><gcmd:keywordVersion xmlns:gcmd="http://gcmd.gsfc.nasa.gov/">DUMMY</gcmd:keywordVersion>
<skos:Concept rdf:about="uuid"></skos:Concept></rdf:RDF>'

  ROOT_SCHEMES = ["chronounits", "sciencekeywords", "locations", "providers", "platforms", "instruments", "projects", "discipline", "idnnode", "isotopiccategory", "rucontenttype", "horizontalresolutionrange", "verticalresolutionrange", "temporalresolutionrange"].sort

  ROOT_LABELS = ["Chronostratigraphic Units", "Science Keywords", "Locations", "Providers", "Platforms", "Instruments", "Projects", "Disciplines", "IDN Nodes", "ISO Topic Categories", "Related URL Content Types", "Horizontal Resolution Ranges", "Vertical Resolution Ranges", "Temporal Resolution Ranges"]

  ISO_TOPICS = ["STRUCTURE", "BIOTA", "CLIMATOLOGY/METEOROLOGY/ATMOSPHERE", "FARMING", "GEOSCIENTIFIC INFORMATION", "TRANSPORTATION", "PLANNING CADASTRE", "INTELLIGENCE/MILITARY", "ELEVATION", "ENVIRONMENT", "LOCATION", "IMAGERY/BASE MAPS/EARTH COVER", "SOCIETY", "BOUNDARIES", "ECONOMY", "UTILITIES/COMMUNICATIONS", "HEALTH", "INLAND WATERS", "OCEANS"].sort

  NO_PROVIDERS = ["NO/CRYOCLIM", "NO/IMR", "NO/MET", "NO/MF/IMR", "NO/MPE/NVE", "NO/NGU", "NO/NILU", "NO/NINA", "NO/NIVA", "NO/NIVA/AKVAPLAN", "NO/NMA", "NO/NMDC/IMR", "NO/NPCA/SOE", "NO/NPI", "NO/NR", "NO/SN"]

  def concept(scheme, version="Jun122012")
    File.join(File.dirname(__FILE__), "../../lib/gcmd/_concepts/", version, scheme)
  end

  context "errors" do
    it "adding concept without skos:Concept should raise Gcmd::Exception" do
      expect { subject.addConcept("root", '<concepts xsi:noNamespaceSchemaLocation="http://gcmd.nasa.gov/kms/gcmd.xsd"></concepts>')
        }.to raise_exception(Gcmd::Exception)
    end
  end

  context "cache" do
    context "should autoload concepts from cache" do
      (["root"]+ROOT_SCHEMES).each do | scheme |
        it scheme do
          subject.concept("isotopiccategory").should_not == ""
      end
      end
    end
  end

  context "#idnnode" do
    it "should list IDN Nodes" do
      subject.idnnode.map {|c| c[1]}.sort.first.should == "AMD"
    end  
  end

  context "#isotopiccategory" do
    it "should list ISO Topic Categories" do
      subject.isotopiccategory.map {|c| c[1]}.sort.should == ISO_TOPICS
    end
  end

  context "#providers" do
    it "should list providers" do
      subject.providers.map {|c| c[1]}.sort.last.should == "ZURICH/GEOG"
    end

    it "select ^NO/" do
      subject.providers.select {|c| c[1] =~ /^NO\//}.map {|c| c[1]}.sort.should == NO_PROVIDERS
    end

  end

  context "#root" do
    it "should list root concepts" do
      subject.root.last.should == ["fb0b9fcd-5c96-4989-8c64-a479bbed83ab", "Projects", ""]
    end
  end

  context "#narrower" do
    it "should list child concepts" do
      subject.narrower("root").map {|r|r[1]}.should == ROOT_LABELS
    end
  end

  context "#schemes" do
    it "should list scheme names" do
      subject.schemes("root").should == ROOT_SCHEMES
    end
  end

  context "#projects" do
    it "should list projects" do
      subject.projects.map {|c|c[1]}.sort.last.should == LAST_PROJECT
    end
  end


  context "#keywordVersion" do
    it "should return the keyword version" do
      subject.keywordVersion.should == "Jun122012"
    end
  end

  context "#fetch" do
    it "should fetch all concepts to cache" do
      http = double("http")
      http.stub(:get => CONCEPT1)
      subject.cache = "/tmp/gcmd-concepts-test"
      subject.http = http 
      subject.fetch("concept1").should == "a9e8d58c35547b3c61014fa590cd519a587dd75b"

    end

  end
end