require "spec_helper"
require "gcmd/dif"
require "nokogiri"
require "json"

describe Gcmd::Dif do
  
  before  do
    @dif = Gcmd::Dif.new
  end

  context "Dash" do
    it "allow properties named after the DIF XML Schema" do
      ["Entry_ID", "Entry_Title", "Data_Set_Citation", "Personnel", "Discipline", "Parameters", "ISO_Topic_Category", "Keyword", "Sensor_Name", "Source_Name", "Temporal_Coverage", "Paleo_Temporal_Coverage", "Data_Set_Progress", "Spatial_Coverage", "Location", "Data_Resolution", "Project", "Quality", "Access_Constraints", "Use_Constraints", "Data_Set_Language", "Originating_Center", "Data_Center", "Distribution", "Multimedia_Sample", "Reference", "Summary", "Related_URL", "Parent_DIF", "IDN_Node", "Originating_Metadata_Node", "Metadata_Name", "Metadata_Version", "DIF_Creation_Date", "Last_DIF_Revision_Date", "DIF_Revision_History", "Future_DIF_Review_Date",
        "Private"].each do | name |
          @dif.send("#{name}".to_sym).should == nil
      end
    end
    it "raise NoMethodError for other properties" do
      lambda { @dif.xyz }.should raise_exception(NoMethodError)
    end
  end

  context "#load_xml" do
    it do
      @dif.load_xml "spec/data/dif_record.xml"
      @dif.valid?.should == false
      @dif.errors.join("").should =~ Regexp.new(Regexp.escape("'TE/VL' is not a v% GCMD concepts provider in //dif:Data_Center_Name/dif:Short_Name[1]").gsub(/%/, Gcmd::Concepts::VERSION))
      @dif.document_to_hash.should == {"Entry_ID"=>"test-doc-001", "Entry_Title"=>"Dif Parsing Test", "Data_Set_Citation"=>{"Dataset_Creator"=>"RDux, CnrdH", "Dataset_Title"=>"Dif Parsing Test"}, "Personnel"=>[{"Role"=>["Investigator", "Technical Contact"], "First_Name"=>"R", "Last_Name"=>"Dux", "Email"=>["rdux@test.to", "rdux.test@account.to"], "Fax"=>"555 125424", "Contact_Address"=>{"Address"=>["Code Test Lane", "Nr.1, Pbox T"], "City"=>"Testsville", "Province_or_State"=>"Testas", "Postal_Code"=>"1351", "Country"=>"Testilvania"}}, {"Role"=>"Investigator", "First_Name"=>"Cnrd", "Last_Name"=>"H", "Email"=>"cnrdh@test.to", "Phone"=>"555 424521", "Contact_Address"=>{"Address"=>["Code Test Road", "Nr.2"], "City"=>"Testsville", "Province_or_State"=>"Testas", "Postal_Code"=>"1351", "Country"=>"Testilvania"}}], "Parameters"=>[{"Category"=>"TEST SCIENCE", "Topic"=>"TEST CLASSIFICATION", "Term"=>"TEST/CLASS", "Variable_Level_1"=>"CODE", "Variable_Level_2"=>"PARSING", "Variable_Level_3"=>"TRANSFORMATION"}, {"Category"=>"XML", "Topic"=>"STANDARDS", "Term"=>"CONVERSION", "Variable_Level_1"=>"XML", "Variable_Level_2"=>"STANDARDS", "Variable_Level_3"=>"CONVERSION"}], "ISO_Topic_Category"=>["CODE", "RUBY", "XML"], "Temporal_Coverage"=>[{"Start_Date"=>"2012-07-28", "Stop_Date"=>"2012-08-1"}, {"Start_Date"=>"2012-08-05", "Stop_Date"=>"2012-08-07"}], "Data_Set_Progress"=>"Complete", "Spatial_Coverage"=>[{"Southernmost_Latitude"=>"75.0", "Northernmost_Latitude"=>"75.0", "Westernmost_Longitude"=>"35.0", "Easternmost_Longitude"=>"35.0"}, {"Southernmost_Latitude"=>"35.0", "Northernmost_Latitude"=>"35.0", "Westernmost_Longitude"=>"75.0", "Easternmost_Longitude"=>"75.0"}], "Location"=>[{"Location_Category"=>"OCEAN", "Location_Type"=>"DEEP OCEAN", "Location_Subregion1"=>"CODE OCEAN", "Location_Subregion2"=>"DEEP CODE BLUE", "Detailed_Location"=>"CODE STRAIT"}, {"Location_Category"=>"GEOGRAPHIC REGION", "Location_Type"=>"CODE COUNTRY"}], "Data_Set_Language"=>"English", "Data_Center"=>{"Data_Center_Name"=>{"Short_Name"=>"TE/VL", "Long_Name"=>"Testicon"}, "Data_Center_URL"=>"http://www.tasti.ts", "Personnel"=>{"Role"=>"Data Center Contact", "First_Name"=>"R", "Last_Name"=>"Dux", "Email"=>["rdux@test.to", "rdux.test@account.to"], "Fax"=>"555 125424", "Contact_Address"=>{"Address"=>["Code Test Lane", "Nr.1, Pbox T"], "City"=>"Testsville", "Province_or_State"=>"Testas", "Postal_Code"=>"1351", "Country"=>"Testilvania"}}}, "Summary"=>{"Abstract"=>"A DIF XML to Hash conversion test to see if all edge cases are handled correctly."}, "IDN_Node"=>[{"Short_Name"=>"TEST/NODE"}, {"Short_Name"=>"TEST"}], "Originating_Metadata_Node"=>"TEST/TS", "Metadata_Name"=>"CEOS IDN DIF", "Metadata_Version"=>"9.8.3", "DIF_Creation_Date"=>"2012-08-07", "Last_DIF_Revision_Date"=>"2012-08-07", "Private"=>"False"}
    end
  end

  context "valid?" do
    it do
      @dif.load_xml "spec/data/dif_record.xml"
      @dif.valid?.should == false
      puts @dif.errors
      @dif.Data_Center[0].Data_Center_Name.Short_Name = "NO/NPI)"
      @dif.valid?.should == true
    end
  end
  
  
  context "to_xml" do
    it do
      @dif.Entry_Title = "New"
      xml = @dif.to_xml.should =~ /\<Entry_Title\>New\<\/Entry_Title\>/
      end
  end
  #context "valid?" do
  #  it do
  #    @dif["Entry_ID"] = "id"
  #    @dif["Entry_Title"] = "Title"
  #    @dif.valid?.should == true
  #    end
  #end
end