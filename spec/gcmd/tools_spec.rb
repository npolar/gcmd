require "spec_helper"
require "gcmd/tools"

require "nokogiri"

describe Gcmd::Tools do
  
  subject do
    Gcmd::Tools.new
  end
  
  def scheme
    subject.load_xml( "spec/data/dif.xsd" )
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
          subject.load_xml( "spec/data/dif.xml" ).should be_a_kind_of( Nokogiri::XML::Document )
        end
        
        it "should accept string formatted data"do
          subject.load_xml( "<DIF></DIF>" ).should be_a_kind_of( Nokogiri::XML::Document )
        end
        
        it "should raise an ArgumentError if the provided source is wrong" do
          expect{ subject.load_xml( "wrong_data.xml" ) }.to raise_error( ArgumentError )
        end
        
      end
        
    end
    
  end
  
end