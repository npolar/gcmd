require "spec_helper"
require "gcmd/tools"

require "nokogiri"

describe Gcmd::Tools do
  
  subject do
    Gcmd::Tools.new
  end
    
  context "Importing data" do
    
    context "XML" do
      
      context "#load_xml" do
        
        it "should accept data from a uri" do          
          # DIF template provided by {http://gcmd.nasa.gov/Aboutus/xml/dif/DIF_XML_Template.xml NASA}
          uri = "http://gcmd.nasa.gov/Aboutus/xml/dif/DIF_XML_Template.xml"          
          subject.load_xml( uri ).should be_a_kind_of( Nokogiri::XML::Document )
        end
        
        it "should accept data from a file" do
          subject.load_xml( "spec/data/dif_record.xml" ).should be_a_kind_of( Nokogiri::XML::Document )
        end
        
        it "should accept string formatted data"do
          subject.load_xml( "<DIF></DIF>" ).should be_a_kind_of( Nokogiri::XML::Document )
        end

        it "should raise an ArgumentError if the provided source is wrong" do
          expect{ subject.load_xml( "wrong_data.xml" ) }.to raise_error( ArgumentError )
        end
        
      end
        
    end    
    
    context "JSON" do
      
      context "#load_json" do
        
        it "should accept data from a uri" do
          # json service reply for NorskPolar
          uri = "http://search.twitter.com/search.json?q=NorskPolar&include_entities=false"
          subject.load_json( uri ).should be_a_kind_of( Hash )
        end
        
        it "should accept data from a file" do
          subject.load_json("spec/data/dif.json").should be_a_kind_of( Hash )
        end
        
        it "should accept string formatted data" do
          subject.load_json('{"dif": [{"Entry_ID": "myEntryID"}]}').should be_a_kind_of( Hash )
        end
        
        it "should raise an ArgumentError if the provided source is wrong" do
          expect{ subject.load_json("23445sdfqw4r.asdfqwe") }.to raise_error( ArgumentError )
        end
        
      end
      
    end
    
  end
  
end