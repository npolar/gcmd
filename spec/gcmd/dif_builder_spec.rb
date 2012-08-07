require "spec_helper"

require "gcmd/dif_builder"
require "nokogiri"

describe Gcmd::DifBuilder do
  
  subject do
    Gcmd::DifBuilder.new
  end
  
  context "Schema" do
    
    it "should have a default schema" do
      subject.schema.should_not be(nil)
    end
    
  end
  
  context "DIF" do
    
    context "#build_dif" do
      
      it "should return a string" do
        subject.build_dif( {"Entry_ID" => "Enter-the-ID"} ).should be_a_kind_of( String )
      end
      
      it "should raise an ArgumentError if no data provided" do
        expect{ subject.build_dif }.to raise_error( ArgumentError )
      end
      
      it "should convert provided elements to XML" do
        subject.build_dif( {"Entry_ID" => "Enter-the-ID"} ).should include( "<Entry_ID>Enter-the-ID</Entry_ID>" )
      end
      
      context "it should contain all required fields" do        
        
        Gcmd::DifBuilder::REQUIRED.each do | required_element |
          
          it required_element do
            subject.build_dif( {"Entry_ID" => "Enter-the-ID"} ).should include( "\<#{ required_element }\>" )
          end
          
        end
        
      end
      
    end
    
  end
    
  context "Convert Hash to XML" do
    
    context "#build_xml" do
      
      it "should return a string" do
        subject.build_xml( {} ).should be_a_kind_of( String )
      end
      
      it "should raise an ArgumentError if no dif_hash is provided" do
        expect{ subject.build_xml }.to raise_error( ArgumentError )
      end
      
      it "should contain the DIF root element" do
        subject.build_xml( {} ).should include( "<DIF" )
      end
      
      it "should convert Hash data to xml data" do
        subject.build_xml( {"myTag" => "Identifier"} ).should include("<myTag>Identifier</myTag>")
      end
   
    end
    
    # @Note Watch out with these tests! Because of the recursive nature providing to complex test data
    #   might trigger a "RuntimeError: Document already has a root node". This is due to the fact that
    #   these methods are ment to be called in the context of a controlling document builder and add
    #   on to that object rather than generate a complete document them selves.
    
    context "#build_from_hash" do
      
      it "should return a nokogiri builder object" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_hash( xml, {} ).should be_a_kind_of( Nokogiri::XML::Builder )
      end
      
      it "should contain an XML representation of a Hash with string value" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_hash( xml, {"abc" => "alphabet"} ).to_xml.should include( "<abc>alphabet</abc>" ) 
      end
      
      it "should return a nokogiri builder object of a Hash with Hash value" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_hash( xml, {"collection" => {}} ).should be_a_kind_of( Nokogiri::XML::Builder )
      end
      
      it "should return a nokogiri builder object of a Hash with Array value" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_hash( xml, {"collection" => []} ).should be_a_kind_of( Nokogiri::XML::Builder )
      end
      
    end
    
    context "#build_from_array" do
      
      it "should return a nokogiri builder object" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_array( xml, "abc", [] ).should be_a_kind_of( Nokogiri::XML::Builder )
      end
      
      it "should return a nokogiri builder object if provided with an array containing strings" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_array( xml, "abc", ["a"] ).should be_a_kind_of( Nokogiri::XML::Builder )
      end
      
      it "should return a nokogiri builder object if provided with an array containing hashes" do
        xml = Nokogiri::XML::Builder.new(:encoding => "UTF-8")
        subject.build_from_array( xml, "abc", [{}] ).should be_a_kind_of( Nokogiri::XML::Builder )
      end
      
    end
    
  end
  
  context "Hash processing" do
    
    context "#sync_with_template" do
      
      it "should return a Hash" do
        subject.sync_with_template( {} ).should be_a_kind_of( Hash )
      end
      
      it "should return the input unaltered of no template is provided" do
        subject.sync_with_template( {"key2" => "val2", "key1" => "val1"} ).should == {"key2" => "val2", "key1" => "val1"}
      end
      
      it "should should sort items according to the template" do
        template = {"Families" => [{
                      "parents" => {"mother" =>"", "father" => ""},
                      "children" => {"child1" => "", "child2" => ""},
                    }]}
        data = {"Families" => [{
                  "parents" => {"mother" =>"Hannah", "father" => "Eric"},
                  "children" => {"child2" => "John", "child1" => "Jane"}
                },{
                  "parents" => {"father" => "John", "mother" =>"Jane" },
                  "children" => {"child1" => "Eric", "child2" => "Hannah"}
                }]}
        subject.sync_with_template( data, template ).should == {"Families" => [{
                  "parents" => {"mother" =>"Hannah", "father" => "Eric"},
                  "children" => {"child1" => "Jane", "child2" => "John"}
                },{
                  "parents" => {"mother" =>"Jane", "father" => "John"},
                  "children" => {"child1" => "Eric", "child2" => "Hannah"}
                }]}
      end
      
      it "should complete the provided hash with elements from the template" do
        template = {"Families" => [{
                      "parents" => {"mother" =>"", "father" => ""},
                      "children" => {"child1" => "", "child2" => ""},
                      "pets" => []
                    }]}
        data = {"Families" => [{
                  "parents" => {"mother" =>"Hannah", "father" => "Eric"},
                  "pets" => ["dog", "hamster"]
                }]}
        subject.sync_with_template( data, template ).should == {"Families" => [{
                  "parents" => {"mother" =>"Hannah", "father" => "Eric"},
                  "children" => {"child1" => "", "child2" => ""},
                  "pets" => ["dog", "hamster"]
                }]}
      end

    end
    
    context "#sync_array" do
      
      it "should return an array" do
        subject.sync_array( [], {"animals" => []} ).should be_a_kind_of( Array )
      end
      
      it "should return the template values if called with an empty array" do
        subject.sync_array( [], {"animals" => []} ).should == [{"animals" => []}]
      end
      
      it "should return an array of hashes if provided with an array of hashes" do
        data = [{"animals" => ["dog", "cow"]},{"animals" => ["pig"]}]
        subject.sync_array( data, {"animals" => []} ).first.should be_a_kind_of( Hash )
        subject.sync_array( data, {"animals" => []} ).first.should == {"animals" => ["dog", "cow"]}
      end
      
      it "should return an array of strings when provided with a string array" do
        subject.sync_array( ["dog", "pig"], "" ).first.should be_a_kind_of( String )
        subject.sync_array( ["pig", "cow"], "" ).first.should == "pig"
      end
      
    end
    
  end

  context "Templates" do
    
    context "#xml_template" do
      
      it "should return a string" do
        subject.xml_template.should be_a_kind_of( String )
      end
      
      it "should include the keys defined in the schema" do
        subject.xml_template.should include("<Personnel>", "<Role>", "<Distribution_Size>")
      end
      
      it "should have no data for the elements" do
        subject.xml_template.should include("<Role></Role>")
      end
      
    end
    
    context "#hash_template" do
      
      it "should not be nil" do
        subject.hash_template.should_not be( nil )
      end
     
      it "should return a Hash" do
        subject.hash_template.should be_a_kind_of( Hash )
      end
      
    end
    
  end
  
end
