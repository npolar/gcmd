require "spec_helper"

require "gcmd/schema"
require "gcmd/tools"

require "nokogiri"

describe Gcmd::Schema do
  
  subject do
    Gcmd::Schema.new( "spec/data/dif.xsd" )
  end
  
  context "Schema Tools" do
    
    context "Template generation" do
      
      context "#hash_template" do
        
        it "should generate a template hash from an XML schema" 
        
        it "should contain elements defined in the schema" 
        
        it "should represent unbounded items as arrays" 
        
        it "should represent items that can only occur once as strings"
        
      end
      
    end
    
    context "Information extraction" do
      
      context "#collect_info" do
        
        it "should return a Hash object" 
        
        it "should contain the elements defined in the schema" 
        
      end
      
      context "#children?" do
        
        it "should return true if the element has children" do
          subject.send( :children?, "DIF" ).should == true
        end
        
        it "should return false if the element doesn't have any children" do
          subject.send( :children?, "Entry_ID" ).should == false
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
          data = subject.load_xml( '<xs:element ref="ele" minOccurs="1" maxOccurs="unbounded"/>' )
          subject.send( :unbounded?, data).should == true
        end
        
        it "should return false when the elements maxOccurs != unbounded" do
          data = subject.load_xml( '<xs:element ref="ele" minOccurs="1" maxOccurs="1"/>' )
          subject.send( :unbounded?, data).should == false
        end
        
      end
      
      context "#required?" do
        
        it "should return true when the elements minOccurs == 1" do
          data = subject.load_xml( '<xs:element ref="ele" minOccurs="1" maxOccurs="unbounded"/>' )
          subject.send( :required?, data).should == true
        end
        
        it "should return false when the elements minOccurs == 0" do
          data = subject.load_xml( '<xs:element ref="ele" minOccurs="0" maxOccurs="unbounded"/>' )
          subject.send( :required?, data).should == false
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