# encoding: utf-8
require File.dirname(__FILE__) + "/../spec_helper"
require "gcmd/dif"

DIF = '<DIF xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xmlns="'+ Gcmd::Dif::NAMESPACE["dif"] +'"
xsi:schemaLocation="'+ Gcmd::Dif::NAMESPACE["dif"] +' http://gcmd.nasa.gov/Aboutus/xml/dif/dif_v'+ Gcmd::Dif::VERSION+'.xsd">'

describe Gcmd::Dif do
  
  before do
    @dif = Gcmd::Dif.new
  end
  
  context "#initialize" do
    it "should set a JSON skeleton with all WANTED fields" do
      @dif.attributes.should == @dif.json_skeleton
    end
  end
  
  it "#json_skeleton should return a Hash with all WANTED fields" do
    wanted = {"Private"=>"", "Project"=>[], "Sensor_Name"=>[], "Parent_DIF"=>[], "IDN_Node"=>[],
      "Related_URL"=>[], "Location"=>[], "Metadata_Version"=>"", "Personnel"=>[], "Entry_Title"=>"",
      "Use_Constraints"=>"", "Temporal_Coverage"=>[], "Data_Set_Citation"=>[], "Metadata_Name"=>"",
      "ISO_Topic_Category"=>[], "Keyword"=>[], "DIF_Creation_Date"=>"", "Quality"=>"", "Source_Name"=>[],
      "Distribution"=>[], "Data_Set_Language"=>[], "Data_Resolution"=>[], "Summary"=>"",
      "Parameters"=>[], "Data_Center"=>[], "Originating_Metadata_Node"=>"", "Spatial_Coverage"=>[], "Entry_ID"=>"",
      "Data_Set_Progress"=>"", "Access_Constraints"=>""}
      
      @dif.json_skeleton.should == wanted
      
  end
  
  
          
  
  #context "Validation" do
  #  
  #  #context "FIELDS" do
  #  #
  #  #  context "must exist in XML Schema" do
  #  #    
  #  #   Gcmd::Dif::FIELDS.each do | field |
  #  #      it "#{field}" do
  #  #        @dif.minOccurs(field).should >= 0 
  #  #      end
  #  #    end
  #  #  end
  #  #end
  #  
  #  it "should find DIF subelement multiplicity in XML Schema" do
  #    
  #    @dif.minOccurs("Entry_ID").should == 1
  #    @dif.maxOccurs("Entry_ID").should == 1
  #    @dif.multiplicity("Entry_Title").should == [1,1]
  #    @dif.multiplicity("Data_Resolution").should == [0, -1]
  #    
  #    expect {@dif.multiplicity("Bad_Name", "ZIF")}.to raise_error(RuntimeError, /Unkown ZIF subelement/)
  #  end
  #  
  #  it "#valid? == true for empty objects" do
  #    @dif.valid?.should == true # empty but valid!
  #  end
  #  
  #  it "#validate == [] for empty objects" do
  #    @dif.validate.should == [] # empty means valid      
  #  end
  #  
  #  
  #end
  #
  #
  #end
  
  context "#to_xml" do
    it "should export DIF XML" do
      
      @dif.load_xml("#{DIF}<Entry_Title>Dubious</Entry_Title></DIF>")
      @dif.to_xml.should match /<Entry_Title>Dubious<\/Entry_Title>/
      
      
    end

  end  
  context "#load_xml should load all fields" do  
    Gcmd::Dif.sequence("DIF").each do |elmt|
      elmt.each do |field,m|
         it field do
            @dif.load_xml("#{DIF}<#{field}>#{field}1</#{field}></DIF>")
            @dif.attributes.has_key?(field).should == true
         end
      end
    end
    
    it "Entry_Title" do
       @dif.load_xml("#{DIF}<Entry_Title>æøåÆØÅ</Entry_Title></DIF>")
       @dif.attributes.should include("Entry_Title" => "æøåÆØÅ")
    end
    
    it "Parameters (Science Keywords)" do
      @dif.load_xml("#{DIF}<Parameters><Category>EARTH SCIENCE</Category><Topic>Cryosphere</Topic><Term>Sea Ice</Term><Variable_Level_1>Ice Edges</Variable_Level_1></Parameters>
<Parameters><Category>EARTH SCIENCE</Category><Topic>Oceans</Topic><Term>Sea Ice</Term><Variable_Level_1>Ice Edges</Variable_Level_1></Parameters></DIF>")
      
      @dif.attributes.should include({"Parameters"=>[{"Variable_Level_1"=>"Ice Edges", "Topic"=>"Cryosphere", "Term"=>"Sea Ice", "Category"=>"EARTH SCIENCE"}, {"Variable_Level_1"=>"Ice Edges", "Topic"=>"Oceans", "Term"=>"Sea Ice", "Category"=>"EARTH SCIENCE"}]})
      
    end
    
    it "Keyword[s]" do
      @dif.load_xml("#{DIF}<Keyword>Svalbard</Keyword><Keyword>Whatever</Keyword></DIF>")
      @dif.attributes["Keyword"].should == ["Svalbard", "Whatever"]
    end
    
    #it "should load Personnel" do
    #  @dif.load_xml("#{DIF}</DIF>")
    #  @dif.attributes.should include({ "Personnel" => nil})
    #  
  end
      
  
    
  describe "#to_xml" do
      
    # to_zml strict sequence
    
    context "should always export REQUIRED fields" do
      Gcmd::Dif::REQUIRED.each do | r |
        it "#{r}" do
          @dif.load_xml("#{DIF}</DIF>")
          @dif.to_xml.should match /<#{r}(\/)?>/
        end 
      end
    end
    end
  
  context "Atomic key mapping" do
    it "updated <= Last_DIF_Revision_Date" do 
      @dif.attributes = { "Last_DIF_Revision_Date" => "2012-12-12" }
      @dif.updated.should == "2012-12-12" 
    end
    
    
    it "#contributors" do
      dif_personnel = [{"Email" => ["email1", "email2"],"First_Name" => "Fn1","Middle_Name" => "Mn1","Role" => ["role1", "role2"],"Contact_Address" => {"Country" => "Norway","Address" => ["addr1","addr2"],"City" => "Tromsø","Province_or_State" => "Troms"},"Last_Name" => "Ln1"}]
      @dif.attributes = { "Personnel" => dif_personnel }
      @dif.contributors.first.should == { "email" => "email1", "first_name" => "Fn1 Mn1", "last_name" => "Ln1", "roles" => ["role1", "role2"], "country" => "Norway", "city" => "Tromsø" }
    end
  end
  

    
  end

  # multiple emails and roles!