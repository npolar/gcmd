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
    concepts = Gcmd::Concepts.new
    concepts.cache = CACHE
    concepts
  end

  CACHE = "/tmp/gcmd-concepts-spec-#{object_id}"
  
  LAST_INSTRUMENT = "CPI PROBES"

  LAST_PROJECT = "ZA ANTARCTIQUE"

  LAST_SCIENCEKEYWORD = "GRAVITY ANOMALIES"

  CONCEPT1 = '<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:skos="http://www.w3.org/2004/02/skos/core#"><gcmd:keywordVersion xmlns:gcmd="http://gcmd.gsfc.nasa.gov/">DUMMY</gcmd:keywordVersion>
<skos:Concept rdf:about="uuid"></skos:Concept></rdf:RDF>'

  ROOT_SCHEMAS = ["chronounits", "sciencekeywords", "locations", "providers", "platforms", "instruments", "projects", "discipline", "idnnode", "isotopiccategory", "rucontenttype", "horizontalresolutionrange", "verticalresolutionrange", "temporalresolutionrange"].sort

  ROOT_LABELS = ["Chronostratigraphic Units", "Science Keywords", "Locations", "Providers", "Platforms", "Instruments", "Projects", "Disciplines", "IDN Nodes", "ISO Topic Categories", "Related URL Content Types", "Horizontal Resolution Ranges", "Vertical Resolution Ranges", "Temporal Resolution Ranges"]

  ISO_TOPICS = ["STRUCTURE", "BIOTA", "CLIMATOLOGY/METEOROLOGY/ATMOSPHERE", "FARMING", "GEOSCIENTIFIC INFORMATION", "TRANSPORTATION", "PLANNING CADASTRE", "INTELLIGENCE/MILITARY", "ELEVATION", "ENVIRONMENT", "LOCATION", "IMAGERY/BASE MAPS/EARTH COVER", "SOCIETY", "BOUNDARIES", "ECONOMY", "UTILITIES/COMMUNICATIONS", "HEALTH", "INLAND WATERS", "OCEANS"].sort

  NO_PROVIDERS = ["NO/CRYOCLIM", "NO/IMR", "NO/MET", "NO/MF/IMR", "NO/MPE/NVE", "NO/NGU", "NO/NILU", "NO/NINA", "NO/NIVA", "NO/NIVA/AKVAPLAN", "NO/NMA", "NO/NMDC/IMR", "NO/NPCA/SOE", "NO/NPI", "NO/NR", "NO/SN"]

  def concept(schema, version=Gcmd::Concepts::VERSION)
    File.join(File.dirname(__FILE__), "../../lib/gcmd/_concepts/", version, schema)
  end

  context "#collection" do
    it "Array of Atomic hashes" do
      subject.collection("instruments")[77].should == {:id=>"00c994a8-64eb-4263-a3fa-85fd902bb91b", :label=>"GTR",
        :title=>"GTR (Instruments > In Situ/Laboratory Instruments > Recorders/Loggers)", :summary=>"",
        :narrower_ids=>[], :changeNote=>"", :collection=>"instruments", :workspace=>:gcmd, :version=>"7.0",
        :lang=>:en, :tree=>:leaf, :narrower=>[],
        :ancestors=>["Recorders/Loggers", "In Situ/Laboratory Instruments", "Instruments"],
        :ancestor_ids=>["ebfff02c-2e5a-476e-aafb-c00167bf2daa", "ff564c87-78f2-47eb-a857-a4bdc0a71ae5", "b2140059-b3ca-415c-b0a7-3e142783ffe8"]
      }
    end
  end

  context "#concept" do
    context "should autoload concepts from cache" do
      (["root"]+ROOT_SCHEMAS).each do | schema |
        it schema do
          subject.class.valid?(subject.concept(schema)).should  == true
        end
      end
    end

    it "should auto-fetch missing concepts" do
      #concepts = double(subject.class.name, :fetch => nil)
      concepts = Gcmd::Concepts.new
      concepts.cache = "/tmp/gcmd-concepts-bogus-#{object_id}"
      concepts.should_receive(:concept).with("instruments")
      concepts.concept("instruments").should == nil
    end
  end

  context "#filter" do
    it "should remove non-matching concept titles" do
      subject.filter("platforms", "space").last[1].should == "SPACELAB-3"
    end  
  end

  context "#idnnode" do
    it "should list IDN Nodes" do
      subject.idnnode.map {|c| c[1]}.sort.first.should == "AMD"
    end  
  end

  context "#isotopiccategory" do
    it "triplets of ISO Topic Categories" do
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
    it "triplet of root concepts" do
      subject.root.last.should == ["fb0b9fcd-5c96-4989-8c64-a479bbed83ab", "Projects", ""]
    end
  end

  context "#narrower" do
    it "triplet of narrower concepts" do
      subject.narrower("root").map {|r|r[1]}.should == ROOT_LABELS
    end
  end

  context "#schemas" do
    it "should list schemas" do
      subject.schemas.should == ROOT_SCHEMAS
    end
    it "should include root given true or 'root'" do
      subject.schemas(true).should == ["root"] + ROOT_SCHEMAS
      subject.schemas("root").should == ["root"] + ROOT_SCHEMAS
    end
  end

  context "#projects" do
    it "triplet of projects" do
      subject.projects.map {|c|c[1]}.sort.last.should == LAST_PROJECT
    end
  end


  context "#keywordVersion" do
    it "should return the keyword version" do
      subject.keywordVersion.should == "7.0"
    end
  end

    context "#sciencekeywords" do
    it "triplet of sciencekeywords" do
      subject.sciencekeywords.last.size.should == 3
      subject.sciencekeywords.last[1].should == LAST_SCIENCEKEYWORD
    end
  end

  context "#fetch" do
    
    before do
      http = double("http")
      http.stub(:get => CONCEPT1)
      subject.http = http 
    end

    after(:each) do
      filename = File.join(CACHE, "DUMMY", "concept1")
      if File.exists? filename
        File.unlink(filename)
        Dir.unlink(File.join(CACHE, "DUMMY"))
        Dir.unlink(CACHE)
      end
    end


    it "should return true on success" do
      subject.fetch("concept1").should == true
    end

    it "should save Concept XML to disk cache" do
      filename = File.join(CACHE, "DUMMY", "concept1")
      subject.fetch("concept1")
      File.exists?(filename).should == true
      File.open(filename).read.should == CONCEPT1
      File.unlink(filename)
    end

    it "fetching invalid Concept XML should raise Gcmd::Exception" do
      subject.http = double("http", :get => "__INVALID__")
      lambda {subject.fetch("invalid1")}.should raise_exception(Gcmd::Exception)
    end

  end

  it "#fetch_all should call fetch for all schemas + root" do
    (subject.class.schemas+["root"]).each do | schema |      
      subject.should_receive(:fetch).with(schema)      
    end
    subject.fetch_all
  end


  context "#names" do
    it "Array of names" do
      subject.names("instruments").last.should == LAST_INSTRUMENT
    end
  end
  
  context "#save(filename, data)" do
    it "should save and return true" do
      data = "#{object_id}"
      subject.save("concept1", data).should == true
    end

    it "should not save if already existing" do
      data = "#{object_id}"
      subject.save("concept1", data)
      subject.save("concept1", data).should == true
    end

    it "should prepend cache if missing in filename"
    # the tests above leave stray concept1 files
  
  end

  context "#addConcept" do
    it "adding concept without skos:Concept should raise Gcmd::Exception" do
      lambda { subject.addConcept("root", '<concepts xsi:noNamespaceSchemaLocation="http://gcmd.nasa.gov/kms/gcmd.xsd"></concepts>')
        }.should raise_exception(Gcmd::Exception)
    end
  end

  context "Class methods" do
    context "Gcmd::Concepts.valid?" do
      it "true on valid Concept XML" do
        Gcmd::Concepts.valid?(CONCEPT1).should == true
      end
      it "false on invalid Concept XML" do
        Gcmd::Concepts.valid?("http://www.w3.org/2004/02/skos/core#/").should == false
      end
    end
  end
end