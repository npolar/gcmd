require "spec_helper"
require "gcmd/hash_builder"

require "nokogiri"
require "json"

describe Gcmd::HashBuilder do
  
  subject do
    Gcmd::HashBuilder.new( "spec/data/dif_record.xml" )
  end
  
  context "Importing XML" do
    
    it "should have a document if initialized with a XML source" do
      subject.document.should be_a_kind_of( Nokogiri::XML::Document )
    end
    
    it "shouldn't have a document if initialized without a XML source" do
      importer = Gcmd::HashBuilder.new
      importer.document.should be( nil )
    end
    
    context "#build_hash_documents" do
      
      it "should return an array" do
        subject.stub( :document_to_object ) {[]}
        subject.build_hash_documents.should be_a_kind_of( Array )
      end
      
      it "should set document if provided with a XML source" do
        importer = Gcmd::HashBuilder.new
        importer.build_hash_documents( "spec/data/dif_record.xml" )
        subject.document.should be_a_kind_of( Nokogiri::XML::Document )
      end
      
      it "should raise an argument error if no document is found" do
        importer = Gcmd::HashBuilder.new
        expect{ importer.build_hash_documents }.to raise_error( ArgumentError )
      end
      
    end
    
    context "#document_to_object" do
      
      it "should return an array" do
        subject.document_to_object.should be_a_kind_of( Array )
        puts subject.document_to_object.to_json
      end
      
      it "the result array should consist of Hashes" do
        subject.document_to_object.each do | doc |
          doc.should be_a_kind_of( Hash )
        end
      end
      
    end
    
    context "#hash_from_xml" do
      
      it "should return a Hash" do
        xml = Nokogiri::XML( "<Root><Element>elData</Element></Root>" ).children
        subject.hash_from_xml( xml ).should be_a_kind_of( Hash )
      end
      
      it "should include non excluded elements" do
        xml = Nokogiri::XML( "<Root><a>b</a></Root>" ).children
        subject.hash_from_xml( xml.children ).should == {"a" => "b" }
      end
      
      it "shouldn't include excluded elements" do
        xml = Nokogiri::XML( "<Root><Fax>123456</Fax></Root>" ).children
        subject.hash_from_xml( xml.children ).should_not include( {"Fax" => "123456" } )
      end
      
      it "should return a String for childless elements" do
        xml = Nokogiri::XML( "<Root><a>b</a></Root>" ).children
        hash = subject.hash_from_xml( xml.children )
        hash["a"].should be_a_kind_of( String )
      end
      
      it "should return a Hash for elements with children" do
        xml = Nokogiri::XML( "<Root><a><b>c</b></a></Root>" ).children
        hash = subject.hash_from_xml( xml.children )
        hash["a"].should be_a_kind_of( Hash )
        hash["a"].should == {"b" => "c"}
      end
      
      it "should return an Array for unbounded elements even if only occuring once" do
        xml = Nokogiri::XML( "<DIF><ISO_Topic_Category>a</ISO_Topic_Category></DIF>" ).children
        hash = subject.hash_from_xml( xml.children )
        hash["ISO_Topic_Category"].should be_a_kind_of( Array )
      end
      
      it "should return an Array with all values for an unbounded element" do
        xml = Nokogiri::XML( "<DIF><Role>a</Role><Role>b</Role></DIF>" ).children
        hash = subject.hash_from_xml( xml.children )
        hash["Role"].should == ["a", "b"]
      end
        
    end
    
  end
  
  context "Import Options" do
    
    context "#excluded?" do
      
      it "should return true if element is declared in Gcmd::HashBuilder::EXCLUDED" do
        subject.send( :excluded?, "Fax" ).should be( true )
      end
      
    end
    
    context "#unbounded?" do
      
      it "should return true if element is defined as unbounded in schema" do
        subject.send( :unbounded?, "Role" ).should be( true )
      end
      
    end
    
  end
  
end
