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

  context "Loading dif_record.xml to self" do
    it do
      @dif.xml= "spec/data/dif_record.xml"
      @dif.should include (JSON.parse(File.read("spec/data/dif_record.json")))
    end
  end

  context "to_xml" do
    it do
      @dif.Entry_Title = "New"
      xml = @dif.to_xml.should =~ /\<Entry_Title\>New\<\/Entry_Title\>/
      end
  end
end