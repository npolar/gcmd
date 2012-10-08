#
#require File.dirname(__FILE__) + "/../spec_helper"
#require "gcmd/parser"
#
#describe Gcmd::KeywordParser do
#  
#  #SCI = File.dirname(__FILE__) + "/../../raw/ScienceKeywords(RDF).xml"
#  #IDN = File.dirname(__FILE__) + "/../../raw/IdnNodes(RDF).xml"
#  RDF = File.dirname(__FILE__) + "/../../raw/Test(RDF).xml"
#  NG_RDF = Nokogiri::XML File.open( RDF ).read
#  NG_CON = Nokogiri::XML( File.open( RDF ).read ).xpath("//skos:Concept")[1]
#  ROOT_CON = Nokogiri::XML( File.open( RDF ).read ).xpath("//skos:Concept")[0]
#  
#  subject do
#    parser = Gcmd::KeywordParser.new
#  end
#  
#  context "RDF Parsing" do
#    context "#grab_concepts" do
#      it "should return an array" do
#        subject.json_concepts( NG_CON ).should be_a_kind_of( Array )
#      end
#      
#      it "array elemens should be hashes" do
#        subject.json_concepts( NG_CON )[0].should be_a_kind_of( Hash )
#      end
#      
#      it "an item should have an id" do
#        subject.json_concepts( NG_CON )[0].should include( :id )
#      end
#      
#      it "an item should have a label" do
#        subject.json_concepts( NG_CON )[0].should include( :label )
#      end
#      
#      it "an item should have a parent" do
#        subject.json_concepts( NG_CON )[0].should include( :parent )
#      end
#      
#      it "an item should have a node type" do
#        subject.json_concepts( NG_CON )[0].should include( :node_type )
#      end
#      
#      it "an item should have children" do
#        subject.json_concepts( NG_CON )[0].should include( :children )
#      end
#      
#      it "the value for children should be an array" do
#        subject.json_concepts( NG_CON )[0][:children].should be_a_kind_of( Array )
#      end
#    end
#    
#    context "#concept_id" do
#      it "should return the ID for a concept element" do
#        subject.concept_id( NG_CON ).should == "myBranch"
#      end
#    end
#
#    context "#concept_label" do
#      it "should return the label of the element with the specified ID" do
#        subject.concept_label( NG_CON ).should == "branchLabel"
#      end
#    end
#    
#    context "#concept_parent" do
#      it "should return the parent ID for the provided concept" do
#        subject.concept_parent( NG_CON ).should == "myRoot"
#      end      
#    end
#    
#    context "#concept_children" do
#      it "should return an array" do
#        subject.concept_children( NG_CON ).should be_a_kind_of( Array )
#      end
#      
#      it "should contain the ID of the children" do
#        subject.concept_children( NG_CON )[0].should == "myLeaf"
#      end
#    end
#    
#    context "#concept_type" do
#      it "should determine the concept type" do
#        subject.concept_type( NG_CON ).should == "branch"
#      end
#    end
#    
#    context "#concept_branch?" do
#      it "should return true if the concept is a branch node" do
#        subject.concept_branch?( NG_CON ).should == true
#      end
#      
#      it "should return false if the concept is not a branch node" do
#        subject.concept_branch?( ROOT_CON ).should == false
#      end
#    end
#    
#    context "#parent_relation" do
#      it "should return a string with the parents in it" do
#        subject.parent_relation( NG_RDF, NG_CON ).should == "branchLabel"
#      end
#    end
#        
#    context "#dump_json" do
#      it "should convert the hash data to json and save it to a file" do
#        subject.dump_json( subject.json_concepts( NG_RDF ))
#        File.exists? "JsonConcepts.json"
#        File.size("JsonConcepts.json").should > 0
#      end
#    end
#  end  
#
#end