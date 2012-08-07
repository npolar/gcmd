require "spec_helper"
require "gcmd/schema"

require "nokogiri"

describe Gcmd::Schema do
  
  subject do
    Gcmd::Schema.new( "spec/data/dif.xsd" )
  end
  
  context "Schema Tools" do
    
    it "should have a default schema" do
      my_schema = Gcmd::Schema.new
      my_schema.schema.should_not be( nil )
    end
    
    context "Template generation" do
      
      context "#hash_template" do
        
        it "should return a Hash object" do
          subject.hash_template.should be_a_kind_of( Hash )
        end
        
        it "should contain elements defined in the schema" do
          subject.hash_template.should include("Entry_ID", "Temporal_Coverage")
        end
        
        it "should represent unbounded items as arrays" do
          subject.hash_template["Personnel"].should be_a_kind_of( Array )
        end
        
        it "should represent items that can only occur once as strings" do
          subject.hash_template["Entry_ID"].should == ""
        end
        
      end
      
      context "#generate_structure" do
        
        it "should return a string if bounded" do
          data = {"unbounded" => false}
          subject.generate_structure( data ).should == ""
        end
        
        it "should return an array if unbounded" do
          data = { "unbounded" => true }
          subject.generate_structure( data ).should be_a_kind_of( Array )
        end
        
        it "should return a Hash if bounded and it has children" do
          data = { "unbounded" => false, "children" => {} }
          subject.generate_structure( data ).should be_a_kind_of( Hash )
        end
        
        it "should return an Array if unbounded and it has children" do
          data = { "unbounded" => true, "children" => {} }
          subject.generate_structure( data ).should be_a_kind_of( Array )
        end
        
      end
      
    end
    
    context "Information extraction" do
      
      context "#info" do
        
        it "should return a Hash object" do
          subject.info.should be_a_kind_of( Hash )
        end
        
        it "should contain the elements from the scheme" do
          subject.info.should include("Entry_ID", "Personnel")
        end
        
        # @todo find a better matcher for partial hashes and test inner hash content like children
        
        it "should contain descriptive information" do
          subject.info.should include("Entry_ID" => {"required" => true ,"unbounded" => false})
        end
        
      end
      
      context "#unbounded" do
        
        it "should return an array" do
          subject.unbounded.should be_a_kind_of( Array )
        end
        
        it "should contain unbounded elements" do
          subject.unbounded.should include( "IDN_Node", "Chronostratigraphic_Unit", "Personnel", "Email" )
        end        
        
      end
      
      context "#has_children?" do
        
        it "should return true if the element has children" do
          subject.send( :has_children?, "DIF" ).should == true
        end
        
        it "should return false if the element doesn't have any children" do
          subject.send( :has_children?, "Entry_ID" ).should == false
        end
        
      end
      
      context "#child?" do
        
        it "should be true if the element is a child" do
          subject.send( :child?, "Entry_ID" ).should == true
        end
        
        # Note that FAX is seen as a root element in the DIF schema declaration
        # I believe this to be a mistake. But since there is no way to indicate
        # that an element is root inside an xml schema the schema is valid
        # Perhaps to allow validation of different documents with once schema?
        # Please note that this can cause trouble!!!
        
        it "should return false if the element isn't a child" do
          subject.send( :child?, "FAX" ).should == false
        end
        
      end
      
      context "#unbounded?" do
        
        it "should return true when the elements maxOccurs == unbounded" do
          data = Nokogiri::XML.parse( '<xs:element ref="ele" minOccurs="1" maxOccurs="unbounded"/>' ).children.first
          subject.send( :unbounded?, data ).should == true
        end
        
        it "should return false when the elements maxOccurs != unbounded" do
          data = Nokogiri::XML.parse( '<xs:element ref="ele" minOccurs="1" maxOccurs="1"/>' ).children.first
          subject.send( :unbounded?, data ).should == false
        end
        
      end
      
      context "#required?" do
        
        it "should return true when the elements minOccurs == 1" do
          data = Nokogiri::XML.parse( '<xs:element ref="ele" minOccurs="1" maxOccurs="unbounded"/>' ).children.first
          subject.send( :required?, data ).should == true
        end
        
        it "should return false when the elements minOccurs == 0" do
          data = Nokogiri::XML.parse( '<xs:element ref="ele" minOccurs="0" maxOccurs="unbounded"/>' ).children.first
          subject.send( :required?, data ).should == false
        end        
        
      end
      
      context "#root?" do
        
        it "should be true if the element is a root" do
          subject.send( :root?, "DIF" ).should == true          
        end
        
        it "should be false if the element isn't a root" do
          subject.send( :root?, "Personnel" ).should == false
        end
        
      end
      
      context "#root" do
        
        # Note that this test passes because of the explicit return statement.
        # This causes the look to exit once DIF is hit (first element in file).
        
        it "should return the root element for the provided XML schema" do
          subject.send( :root ).should == "DIF"
        end
        
      end
      
    end
    
  end  
  
end